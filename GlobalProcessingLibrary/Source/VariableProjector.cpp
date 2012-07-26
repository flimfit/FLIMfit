
#define CMINPACK_NO_DLL

#define INVALID_INPUT -1

#include "VariableProjector.h"

#include "cminpack.h"
#include <math.h>
#include "util.h"

#include <boost/bind.hpp>
#include <boost/function.hpp>



VariableProjector::VariableProjector(Tada ada, int* gc, int smax, int l, int nl, int nmax, int ndim, int p, double *t) : 
   ada(ada), gc(gc), smax(smax), l(l), nl(nl), nmax(nmax), p(p), t(t)
{

   // Set up buffers for levmar algorithm
   //---------------------------------------------------
   int buf_dim = max(1,nl);
   
   fjac = new double[buf_dim * buf_dim];
   diag = new double[buf_dim];
   qtf  = new double[buf_dim];
   wa1  = new double[buf_dim];
   wa2  = new double[buf_dim];
   wa3  = new double[buf_dim];
   wa4  = new double[buf_dim];
   ipvt = new int[buf_dim];

   for(int i=0; i<nl; i++)
      diag[i] = 1;


   // Set up buffers for variable projection
   //--------------------------------------------------

   a   = new double[ nmax * ( l + smax ) ]; //free ok
   b   = new double[ ndim * ( p + 3 ) ]; //free ok
   u   = new double[ l ];
   kap = new double[ nl + 1 ];

   lp1 = l+1;
   
}

VariableProjector::~VariableProjector()
{

   delete[] fjac;
   delete[] diag;
   delete[] qtf;
   delete[] wa1;
   delete[] wa2;
   delete[] wa3;
   delete[] wa4;
   delete[] ipvt;

   delete[] a;
   delete[] b;
   delete[] u;
   delete[] kap;
   
}

int VariableProjector::Init()
{
   int j, k, inckj;

   // Check for valid input
   //----------------------------------

   if  (!(             l >= 0
          &&          nl >= 0
          && (nl<<1) + 3 <= ndim
          &&           n <  nmax
          &&           n <  ndim
          &&           s >  0
          && !(nl == 0 && l == 0)))
   {
      return INVALID_INPUT;
   }


   // Get inc matrix and check for valid input
   // Determine number of constant functions
   //------------------------------------------

   nconp1 = l+1;
   philp1 = l == 0;

   if ( l > 0 && nl > 0 )
   {
      //model->GetIncMatrix(inc);

      p = 0;
      for (j = 0; j < lp1; ++j) 
      {
         if (p == 0) 
            nconp1 = j;
         for (k = 1; k <= nl; ++k) 
         {
            inckj = inc[k + j * 12];
            if (inckj != 0 && inckj != 1)
               break;
            if (inckj == 1)
               p++;
         }
      }

      // Determine if column L+1 is in the model
      //---------------------------------------------
      philp1 = false;
      for (k = 1; k <= nl; ++k) 
         philp1 = philp1 | (inc[k + lp1 * 12] == 1); 
   }

   ncon = nconp1 - 1;

   return 0;
}


int VariableProjector::Fit(int s, int n, float* y, float *w, double *alf, double *lin_params, int thread, int itmax, int& niter, int &ierr, double& c2)
{

   int lnls1 = l + s + nl + 1;
   int lp1   = l + 1;
   int nsls1 = n * s - l * (s - 1);
   
   this->y = y;
   this->w = w;

   this->thread = thread;

   double ftol = sqrt(dpmpar(1));
   double xtol = sqrt(dpmpar(1));
   double gtol = 0.;
   double factor = 1;

   int    maxfev = 100;

   int nfev, info;

   // Bind the member variable 
   boost::function<int(void*, int, int, const double*, double*, double*, int)> varproj_ref;
   varproj_ref = boost::bind(&VariableProjector::varproj, this, _1, _2, _3, _4, _5, _6, _7);
   minpack_funcderstx_mn target = *varproj_ref.target<minpack_funcderstx_mn>();

   info = lmstx(target, NULL, nsls1, nl, alf, fjac, nl,
                 ftol, xtol, gtol, itmax, diag, 1, factor, -1,
                 &nfev, &niter, &c2, ipvt, qtf, wa1, wa2, wa3, wa4 );

   if (info < 0)
      ierr = info;
   else
      ierr = niter;
   return 0;

}


double VariableProjector::d_sign(double *a, double *b)
{
   double x;
   x = (*a >= 0 ? *a : - *a);
   return( *b >= 0 ? x : -x);
}

int VariableProjector::varproj(void *pa, int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag)
{
   int j, k, kp1, i__1, i__2;
   int lastca, firstca, firstcb, firstr;

   int isel;
   int d_idx = -1;

   int     lnls = l + nl + s;
   int     lps  = l + s;

   double *r__  = a + l * n;

   if (terminate)
      return -9;

   // Matrix dimensions
   int r_dim1 = n;
   int y_dim1 = nmax;
   int a_dim1 = n;
   int b_dim1 = ndim;
   int t_dim1 = nmax;

   double d__1;
   double rn;

   double beta, acum;
   double alpha;

/*     ============================================================== */

/*        COMPUTE THE NORM OF THE RESIDUAL (IF ISEL = 1 OR 2), OR THE */
/*        (N-L) X NL X S DERIVATIVE OF THE MODIFIED RESIDUAL (N-L) BY S */
/*        MATRIX Q2*Y (IF ISEL = 1 OR 3).  HERE Q * PHI = TRI, I.E., */

/*         L     ( Q1 ) (     .   .        )   (TRI . R1 .  F1  ) */
/*               (----) ( PHI . Y . D(PHI) ) = (--- . -- . ---- ) */
/*         N-L   ( Q2 ) (     .   .        )   ( 0  . R2 .  F2  ) */

/*                 N       L    S      P         L     S     P */

/*        WHERE Q IS N X N ORTHOGONAL, AND TRI IS L X L UPPER TRIANGULAR. */
/*        THE NORM OF THE RESIDUAL = FROBENIUS NORM(R2), AND THE DESIRED */
/*        DERIVATIVE ACCORDING TO REF. (5), IS */
/*                                                 -1 */
/*                    D(Q2 * Y) = -Q2 * D(PHI)* TRI  * Q1* Y. */

/*        THE THREE-TENSOR DERIVATIVE IS STORED IN COLUMNS L+S+1 THROUGH */
/*        L+S+NL AND ROWS L+1 THROUGH S*N - (S-1)*L OF THE MATRIX A. */
/*        THE MATRIX SLAB OF THE DERIVATIVE CORRESPONDING TO THE K'TH */
/*        RIGHT HAND SIDE (FOR K=1,2,...,S) IS IN ROWS L+(K-1)*(N-L)+1 */
/*        THROUGH L+K*(N-L). */

/*     .................................................................. */


   isel = iflag + 1;
   if (isel > 3)
   {
      d_idx = isel - 3;
      
      jacb_row(s, l, n, ndim, nl, lp1, ncon, nconp1, inc, b, kap, NULL, r__, d_idx, rnorm, fjrow);
      return iflag;
   }


   if (isel == 1)
   {
      firstca = 0;
      lastca = lps;
      firstcb = 0;
      firstr = l;
      i__1 = 1;
      (*ada)(s, lp1, nl, n, nmax, ndim, p, a, b, kap, inc, t, alf, &i__1, gc, thread);
/*
      init_(s, l, nl, n, nmax, ndim, p, t,
          w, alf, ada, isel, a, b, kap, 
          inc, &ncon, &nconp1, &philp1, &nowate, gc, thread); */
   }
   else
   {
      i__1 = min(isel,3);
      (*ada)(s, lp1, nl, n, nmax, ndim, p, a, b, kap, inc, t, alf, &i__1, gc, thread);

      if (isel > 2)
      {
         // *isel = 3 or 4
         firstcb = 0;
         firstca = -1;
         firstr = (4 - isel) * l;
      }
      else
      {
         // *isel = 2
         firstca = ncon;
         firstcb = -1;
      }
   }

   if (isel < 3)
   {
      // *isel = 1 or 2
      if (!philp1)
      {
         // Store the data in r__
         #pragma omp parallel for
         for (j = 0; j < s; ++j)
            for (int i = 0; i < n; ++i)
               r__[i + j * r_dim1] = y[i + j * y_dim1];
      }
      else
      {
         // Store the data in r__, subtracting the column l+1 which does not
         // have a linear parameter
         #pragma omp parallel for
         for(j=s-1; j > 0; --j)
            for(int i=0; i < n; ++i)
               r__[i + j * r_dim1] = y[i + j * y_dim1] - r__[i + r_dim1];
        
         for(int i=0; i < n; ++i)
            r__[i + r_dim1] = y[i + y_dim1] - r__[i + r_dim1];
      }
   }
    
   // Weight columns
   if (w != NULL)
   { 
      if (firstca >= 0)
      {
         #pragma omp parallel for
         for (j = firstca; j < lps; ++j)
            for (int i = 0; i < n; ++i)
               a[i + j * a_dim1] *= w[i];
      }
      if (firstcb >= 0)
      {
         for (j = firstcb; j < p; ++j)
            for (int i = 0; i< n; ++i)
               b[i + j * b_dim1] *= w[i];
      }
   }
   

/*           COMPUTE ORTHOGONAL FACTORIZATIONS BY HOUSEHOLDER */
/*           REFLECTIONS.  IF ISEL = 1 OR 2, REDUCE PHI (STORED IN THE */
/*           FIRST L COLUMNS OF THE MATRIX A) TO UPPER TRIANGULAR FORM, */
/*           (Q*PHI = TRI), AND TRANSFORM Y (STORED IN COLUMNS L+1 */
/*           THROUGH L+S), GETTING Q*Y = R.  IF ISEL = 1, ALSO TRANSFORM */
/*           J = D PHI (STORED IN COLUMNS L+S+1 THROUGH L+P+S OF THE */
/*           MATRIX A), GETTING Q*J = F.  IF ISEL = 3 OR 4, PHI HAS */
/*           ALREADY BEEN REDUCED, TRANSFORM ONLY J.  TRI, R, AND F */
/*           OVERWRITE PHI, Y, AND J, RESPECTIVELY, AND A FACTORED FORM */
/*           OF Q IS SAVED IN U AND THE LOWER TRIANGLE OF PHI. */

   if (l > 0)
   {
      // Compute orthogonal factorisations by householder reflection (phi)
      for (k = 0; k < l; ++k) 
      {
         kp1 = k + 1;

         // If *isel=1 or 2 reduce phi (first l columns of a) to upper triangular form
         if (isel <= 2 && !(isel == 2 && k<ncon))
         {
            i__2 = n - k;
            d__1 = enorm(i__2, &a[k + k * a_dim1]);
            alpha = d_sign(&d__1, &a[k + k * a_dim1]);
            u[k] = a[k + k * a_dim1] + alpha;
            a[k + k * a_dim1] = -alpha;
            firstca = kp1;
            if (alpha == (float)0.)
            {
               isel = -8;
               goto L99;
            }
         }

         beta = -a[k + k * a_dim1] * u[k];

         // Compute householder reflection of phi
         if (firstca >= 0)
         {
            for (j = firstca; j < l; ++j)
            {
               acum = u[k] * a[k + j * a_dim1];

               for (int i = kp1; i < n; ++i) 
                  acum += a[i + k * a_dim1] * a[i + j * a_dim1];
               acum /= beta;

               a[k + j * a_dim1] -= u[k] * acum;
               for (int i = kp1; i < n; ++i) 
                  a[i + j * a_dim1] -= a[i + k * a_dim1] * acum;
            }
         }

      }

      for (k = 0; k < l; ++k) 
      {
         kp1 = k + 1;

         beta = -a[k + k * a_dim1] * u[k];

         // Transform Y, getting Q*Y=R 
         if (firstca >= 0)
         {
            for (j = l; j < lps; ++j)
            {
               acum = u[k] * a[k + j * a_dim1];

               for (int i = kp1; i < n; ++i) 
                  acum += a[i + k * a_dim1] * a[i + j * a_dim1];
               acum /= beta;

               a[k + j * a_dim1] -= u[k] * acum;
               for (int i = kp1; i < n; ++i) 
                  a[i + j * a_dim1] -= a[i + k * a_dim1] * acum;
            }
         }

         // Transform J=D(phi)
         if (firstcb >= 0) 
         {
            for (j = firstcb; j < p; ++j)
            {
               acum = u[k] * b[k + j * b_dim1];
               for (int i = k; i < n; ++i) 
                  acum += a[i + k * a_dim1] * b[i + j * b_dim1];
               acum /= beta;

               b[k + j * b_dim1] -= u[k] * acum;
               for (int i = k; i < n; ++i) 
                  b[i + j * b_dim1] -= a[i + k * a_dim1] * acum;
            }
         }
      }
   }

   if (isel < 3)
   {
   /*           COMPUTE THE FROBENIUS NORM OF THE RESIDUAL MATRIX: */
   
      *rnorm = 0.0;
      rn = 0;

      #pragma omp parallel for reduction(+: rn) private(d__1,i__2)  
      for (j = 0; j < s; ++j) 
      {
         i__2 = n - l;
         /* Computing 2nd power */
         d__1 = enorm(i__2, &r__[l + j * r_dim1]);
                  
         rn += d__1 * d__1;
      }
      rn += kap[0] * kap[0];
      *rnorm = sqrt(rn);
   
   }
   else
   {
   /*           F2 IS NOW CONTAINED IN ROWS L+1 TO N AND COLUMNS L+S+1 TO */
   /*           L+P+S OF THE MATRIX A.  NOW SOLVE THE S (L X L) UPPER */
   /*           TRIANGULAR SYSTEMS TRI*BETA(J) = R1(J) FOR THE LINEAR */
   /*           PARAMETERS BETA.  BETA OVERWRITES R1. */
   
      if (l != 0)
      {   
         #pragma omp parallel for
         for (j = 0; j < s; ++j) 
            bacsub_(n, l, a, &r__[j * r_dim1]);
      }

      /*           MAJOR PART OF KAUFMAN'S SIMPLIFICATION OCCURS HERE.  COMPUTE */
      /*           THE DERIVATIVE OF ETA WITH RESPECT TO THE NONLINEAR */
      /*           PARAMETERS */

      /*   T   D ETA        T    L          D PHI(J)    D PHI(L+1) */
      /*  Q * --------  =  Q * (SUM BETA(J) --------  + ----------)  =  F2*BETA */
      /*      D ALF(K)          J=1         D ALF(K)     D ALF(K) */

      /*           AND STORE THE RESULT IN COLUMNS L+S+1 TO L+NL+S.  THE */
      /*           FIRST L ROWS ARE OMITTED.  THIS IS -D(Q2)*Y.  THE RESIDUAL */
      /*           R2 = Q2*Y (IN COLUMNS L+1 TO L+S) IS COPIED TO COLUMN */
      /*           L+NL+S+1. */

      jacb_row(s, l, n, ndim, nl, lp1, ncon, nconp1, inc, b, kap, NULL, r__, 0, rnorm, fjrow);

      
   }

L99:
   if (isel < 0)
      iflag = isel;
    return iflag;
}


/*
int lmvarp_getlin(int s, int l, int nl, int n, int nmax, int ndim, int p, double *t, float *y, 
   float *w, double *ws, Tada ada, double *a, double *b, double *c,
   integer *gc, int thread, integer *static_store, 
   double *alf, double *beta)
*/
int VariableProjector::GetLinearParams(int s, double* alf, double* beta, int thread)
{
   int lnls1 = l + s + nl + 1;
   int lp1 = l + 1;
   int nsls1 = n * s - l * (s - 1);

   this->y = y;
   this->thread = thread;

   varproj(NULL, nsls1, nl, alf, wa1, wa2, 0);
   varproj(NULL, nsls1, nl, alf, wa1, wa2, 2);
       
   int ierr = 0;
   postpr_(s, l, nl, n, nmax, ndim, lnls1, p, alf, w, a, b, &a[l * n], beta, &ierr);

   int c__2 = 1;
   (*ada)(s, lp1, nl, n, nmax, ndim, p, a, b, 0, inc, t, alf, &c__2, gc, thread);

   return 0;
}

