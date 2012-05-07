#include "ModelADA.h"
#include "VariableProjection.h"


#ifdef __cplusplus
extern "C" {
#endif
#include "f2c.h"

#ifndef NO_OMP   
#include <omp.h>
#endif
   
#include <emmintrin.h>


/* Table of constant values */

static integer c__1 = 1;
static integer c__3 = 3;

// u   -> beta
// r__ -> &a[lp1 * a_dim1 + 1]

void jacb_row(int *s, int *l, int *n, int *ndim, int *nl, int lp1, int ncon, 
              int nconp1, int* inc, double* b, double *kap, double* r__, int d_idx, double* res, double* derv);



int varproj(void *pa, int nsls1, int nls, const double *alf, double *rnorm, double *fjrow, int iflag)
{

   varp_param* vp = (varp_param*) pa;
   int *s      = (vp->s);
   int *l      = (vp->l);
   int *n      = (vp->n);
   int *nmax   = (vp->nmax);
   int *ndim   = (vp->ndim);
   int *p      = (vp->p);
   int *nl     = &nls;

   int *thread = (vp->thread);

   double *t = vp->t;
   double *y = vp->y;
   double *w = vp->w;

   double *a   = vp->a;
   double *b   = vp->b;
   double *u   = vp->beta;
   double *r__ = a + *l * *n;

   double *kap = b + *ndim * (*p+2);


   if (vp->terminate != NULL && *vp->terminate)
      return -9;

   int *gc = vp->gc;
   int *static_store = vp->static_store;
   S_fp ada = vp->ada;

   int isels;
   int* isel = &isels;
   int d_idx = -1;


    /* System generated locals */
    integer a_dim1, a_offset, b_dim1, b_offset, t_dim1, t_offset, r_dim1, 
    r_offset, y_dim1, y_offset, i__1, i__2;
    doublereal d__1;
    double rn;

    /* Builtin functions */
    double d_sign(doublereal *, doublereal *), sqrt(doublereal);

    integer& lp1    = static_store[0];
    integer& ncon   = static_store[1];
    integer& philp1 = static_store[2];
    integer& nconp1 = static_store[3];
    integer& nowate = static_store[4];

    integer* inc = static_store + 5;



    /* Local variables */
    integer j, k;
    integer kp1;
    integer lsp1;
    doublereal beta, acum;
    integer lnls, lnls1;
    doublereal alpha;
    extern /* Subroutine */ int bacsub_(integer *, integer *, doublereal *, 
       doublereal *);
    integer lastca, lastcb;
    integer firstr, firstca, firstcb;

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


    /* Parameter adjustments */
   --u;
   --alf;
   r_dim1 = *n;
   r_offset = 1 + r_dim1;
   r__ -= r_offset;
   --w;
   y_dim1 = *nmax;
   y_offset = 1 + y_dim1;
   y -= y_offset;
   a_dim1 = *n;
   a_offset = 1 + a_dim1;
   a -= a_offset;
   b_dim1 = *ndim;
   b_offset = 1 + b_dim1;
   b -= b_offset;


   t_dim1 = *nmax;
   t_offset = 1 + t_dim1;
   t -= t_offset;



   lnls = *l + *nl + *s;
   lnls1 = lnls + 1;
   lsp1 = *l + *s + 1;

   int lps = *l+*s;


   *isel = iflag + 1;
   if (*isel > 3)
   {
      d_idx = *isel - 3;
      
      jacb_row(s, l, n, ndim, nl, lp1, ncon, nconp1, inc, b, kap, r__, d_idx, rnorm, fjrow);
      return iflag;
   }



   if (*isel == 1)
   {
      lp1 = *l + 1;
      firstca = 1;
      lastca = lps;
      firstcb = 1;
      lastcb = *p;
      firstr = lp1;
      init_(s, l, nl, n, nmax, ndim, p, &t[t_offset], &
          w[1], &alf[1], (S_fp)ada, isel, &a[a_offset], &b[b_offset], kap, 
          inc, &ncon, &nconp1, &philp1, &nowate, gc, thread);
   }
   else
   {
      i__1 = min(*isel,3);
      (*ada)(s, &lp1, nl, n, nmax, ndim, p, &a[a_offset], &b[
          b_offset], kap, inc, &t[t_offset], &alf[1], &i__1, gc, thread);

      if (*isel > 2)
      {
   /*                                                 ISEL = 3 OR 4 */
         firstcb = 1;
         lastcb = *p;
         firstca = 0;
         firstr = (4 - *isel) * *l + 1;
      }
      else
      {
      /*                                                 ISEL = 2 */
         firstca = nconp1;
         lastca = lps;
         firstcb = 0;
      }
   }

   if (*isel < 3)
   {
   /*                                                  ISEL = 1 OR 2 */
      if (!philp1)
      {
         #pragma omp parallel for
         for (j = 1; j <= *s; ++j)
            for (int i = 1; i <= *n; ++i)
               r__[i + j * r_dim1] = y[i + j * y_dim1];
      }
      else
      {
         #pragma omp parallel for
         for(j=*s; j > 1; --j)
            for(int i=1; i <= *n; ++i)
               r__[i + j * r_dim1] = y[i + j * y_dim1] - r__[i + r_dim1];
        
         for(int i=1; i <= *n; ++i)
            r__[i + r_dim1] = y[i + y_dim1] - r__[i + r_dim1];
      }
   }
    
/*                                             WEIGHT APPROPRIATE COLUMNS */
   
   if (!nowate)
   { 
   
      if (firstca != 0)
      {
         #pragma omp parallel for
         for (j = firstca; j <= lastca; ++j)
            for (int i = 1; i <= *n; ++i)
               a[i + j * a_dim1] *= w[i];
      }
      if (firstcb != 0)
      {
         for (j = firstcb; j <= lastcb; ++j)
            for (int i = 1; i<= *n; ++i)
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

   if (*l > 0)
   {
   
      for (k = 1; k <= *l; ++k) 
      {
         kp1 = k + 1;
         if (*isel <= 2 && !(*isel == 2 && k<nconp1)) // (!(*isel >= 3 || *isel == 2 && k < nconp1))
         {
            i__2 = *n + 1 - k;
            d__1 = xnorm_(&i__2, &a[k + k * a_dim1]);
            alpha = d_sign(&d__1, &a[k + k * a_dim1]);
            u[k] = a[k + k * a_dim1] + alpha;
            a[k + k * a_dim1] = -alpha;
            firstca = kp1;
            if (alpha == (float)0.)
            {
               *isel = -8;
               goto L99;
            }
         }

         beta = -a[k + k * a_dim1] * u[k];

         if (firstca != 0)
         {
            for (j = firstca; j <= lastca; ++j)
            {
               acum = u[k] * a[k + j * a_dim1];

               for (int i = kp1; i <= *n; ++i) 
                  acum += a[i + k * a_dim1] * a[i + j * a_dim1];
               acum /= beta;

               a[k + j * a_dim1] -= u[k] * acum;
               for (int i = kp1; i <= *n; ++i) 
                  a[i + j * a_dim1] -= a[i + k * a_dim1] * acum;
            }
         }

         if (firstcb != 0) 
         {
            for (j = firstcb; j <= lastcb; ++j)
            {
               acum = u[k] * b[k + j * b_dim1];
               for (int i = kp1; i <= *n; ++i) 
                  acum += a[i + k * a_dim1] * b[i + j * b_dim1];
               acum /= beta;

               b[k + j * b_dim1] -= u[k] * acum;
               for (int i = kp1; i <= *n; ++i) 
                  b[i + j * b_dim1] -= a[i + k * a_dim1] * acum;
            }
         }
      }
   }

   if (*isel < 3)
   {
   /*           COMPUTE THE FROBENIUS NORM OF THE RESIDUAL MATRIX: */
   
      *rnorm = 0.0;
      rn = 0;

      #pragma omp parallel for reduction(+: rn) private(d__1,i__2)  
      for (j = 1; j <= *s; ++j) 
      {
         i__2 = *n - *l;
         /* Computing 2nd power */
         d__1 = xnorm_(&i__2, &r__[lp1 + j * r_dim1]);
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
   
      if (*l != 0)
      {   
         #pragma omp parallel for
         for (j = 1; j <= *s; ++j) 
            bacsub_(n, l, &a[a_offset], &r__[j * r_dim1 + 1]);
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

      jacb_row(s, l, n, ndim, nl, lp1, ncon, nconp1, inc, b, kap, r__, 0, rnorm, fjrow);

      
   }

L99:
   if (*isel < 0)
      iflag = *isel;
    return iflag;
} /* dpa_ */

void jacb_row(int *s, int *l, int *n, int *ndim, int *nl, int lp1, int ncon, 
              int nconp1, int* inc, double* b, double *kap, double* r__, int d_idx, double* res, double* derv)
{
   int m, k, j, ksub, b_dim1, r_dim1;
   double acum;

   b_dim1 = *ndim;
   r_dim1 = *n;

   int lps = *l+*s;
   
   if (d_idx == 0)
   {
      *res = kap[0];

      for(j=0; j<*nl; j++)
         derv[j] = kap[j+1];
      return;
   }

   d_idx--;
   

   //for (int i = *l + 1; i <= *n; ++i)
   //{
   //   for (isback = 1; isback <= *s; ++isback) 
   //   {
   int i = d_idx % (*n-*l) + 1 + *l;
   int isback = d_idx / (*n-*l) + 1;


   int is = *s - isback + 1;
   int isub = (*n - *l) * (is - 1) + i;
   
   if (*l != ncon) 
   {
      m = 0;
      for (k = 1; k <= *nl; ++k)
      {
         acum = (float)0.;
         for (j = nconp1; j <= *l; ++j) 
         {
            if (inc[k + j * 12 - 13] != 0) 
            {
               ++m;
               acum += b[i + m * b_dim1] * r__[j + is * r_dim1];
            }
         }
         ksub = lps + k;
         if (inc[k + lp1 * 12 - 13] != 0)
         {   
            ++m;
            acum += b[i + m * b_dim1];
         }

         derv[k-1] = -acum;

      }
   }
   *res = r__[i+is*r_dim1];
   //   }
   //}
}


/*     ============================================================== */
doublereal xnorm_(integer *n, doublereal *x)
{
    /* System generated locals */
    doublereal ret_val, d__1;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    //integer i__;
    doublereal sum, rmax, term;

/*     ============================================================== */

/*        COMPUTE THE L2 (EUCLIDEAN) NORM OF A VECTOR, MAKING SURE TO */
/*        AVOID UNNECESSARY UNDERFLOWS.  NO ATTEMPT IS MADE TO SUPPRESS */
/*        OVERFLOWS. */


/*           FIND LARGEST (IN ABSOLUTE VALUE) ELEMENT */
    /* Parameter adjustments */
   --x;

    /* Function Body */
   rmax = 0.0;
   //#pragma omp parallel for private(d__1)
   for (int i = 1; i <= *n; ++i)
   {
      d__1 = fabs(x[i]);
      //#pragma omp critical
      {
      if (d__1  > rmax) 
         rmax = d__1;
      }
   }

   sum = 0.0;
   if (rmax != 0.0) 
   {
      //#pragma omp parallel for reduction(+:sum) private(term)
      for (int i = 1; i <= *n; ++i) 
      {
         term = 0.0;
         if (rmax + (d__1 = x[i], fabs(d__1)) != rmax) 
            term = x[i] / rmax;
         sum += term * term;
      }
   }

    ret_val = rmax * sqrt(sum);
    return ret_val;
} /* xnorm_ */



/*     ============================================================== */
/* Subroutine */ int init_(integer *s, integer *l, integer *nl,
    integer *n, integer *nmax, integer *ndim, integer *
   p, doublereal *t, doublereal *w, 
   const doublereal *alf, S_fp ada, integer *isel, doublereal 
   *a, doublereal *b, doublereal *kap, integer *inc, integer *ncon, integer *nconp1, 
   logical *philp1, logical *nowate, integer *gc, integer *thread)
{
    /* System generated locals */
    integer a_dim1, a_offset, b_dim1, b_offset, t_dim1, t_offset, i__2;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    integer ncon_buf__, i__, j, k, nconp1_buf__, lp1, lnls1, inckj, philp1_buf__;

/*     ============================================================== */

/*        CHECK VALIDITY OF INPUT PARAMETERS, AND DETERMINE NUMBER OF */
/*        CONSTANT FUNCTIONS. */
/*     .................................................................. */


    /* Parameter adjustments */
    --alf;
    --w;
    a_dim1 = *n;
    a_offset = 1 + a_dim1;
    a -= a_offset;
    b_dim1 = *ndim;
    b_offset = 1 + b_dim1;
    b -= b_offset;
    t_dim1 = *nmax;
    t_offset = 1 + t_dim1;
    t -= t_offset;
    inc -= 13;

    /* Function Body */
    lp1 = *l + 1;
    lnls1 = *l + *s + *nl + 1;
    nconp1_buf__ = 0;

/*     NOWATE = .TRUE. */
    *nowate = FALSE_;
   nconp1_buf__ = lp1;
   ncon_buf__ = *l;
   philp1_buf__ = *l == 0;


/*                                          CHECK FOR VALID INPUT */
    if (*l >= 0 && *nl >= 0 && *s * *l + *nl < *s * *n && (
       *nl << 1) + 3 <= *ndim && *n <= *nmax && *n <= *ndim &&
        ! (*nl == 0 && *l == 0) && * // && *s * *n - (*s - 1) * *l <= *ndim
       s > 0) {
   goto L3;
    }
    *isel = -4;
    goto L99;

/*    1 IF (L .EQ. 0 .OR. NL .EQ. 0) GO TO 3 */
/*         DO 2 J = 1, LP1 */
/*            DO 2 K = 1, NL */
/*    2          INC(K, J) = 0 */


L3:
    (*ada)(s, &lp1, nl, n, nmax, ndim, p, &a[a_offset], &b[
       b_offset], kap, &inc[13], &t[t_offset], &alf[1], isel, gc, thread);

   for (i__ = 1; i__ <= *n; ++i__)
   {
      if (w[i__] < (float)0.) 
      {
         /*                                                ERROR IN WEIGHTS */
         *isel = -6;
         goto L99;
      }
      w[i__] = sqrt(w[i__]);
   }

/*     PHILP1 = .TRUE. */
   if (*l == 0 || *nl == 0) 
   {
      goto L99;
   }
/*                                   CHECK INC MATRIX FOR VALID INPUT AND */
/*                                   DETERMINE NUMBER OF CONSTANT FCNS. */
   p = 0;
   for (j = 1; j <= lp1; ++j) 
   {
      if (p == 0) 
         nconp1_buf__ = j;
      i__2 = *nl;
      for (k = 1; k <= i__2; ++k) 
      {
         inckj = inc[k + j * 12];
         if (inckj != 0 && inckj != 1)
            goto L20;
         if (inckj == 1)
            ++p;
      }
   }

/*                                 DETERMINE IF PHI(L+1) IS IN THE MODEL. */
L20:
    i__2 = *nl;
    for (k = 1; k <= i__2; ++k) {
/* L25: */
   if (inc[k + lp1 * 12] == 1) {
       philp1_buf__ = TRUE_;
   }
    }

L99:
    ncon_buf__ = nconp1_buf__ - 1;
    *ncon = ncon_buf__;
    *nconp1 = nconp1_buf__;
    *philp1 = philp1_buf__;
    return 0;
/* L210: */
} /* init_ */

/*     ============================================================== */
/* Subroutine */ int bacsub_(integer *ndim, integer *n, doublereal *a, 
   doublereal *x)
{
    /* System generated locals */
    integer a_dim1, a_offset, i__1, i__2;

    /* Local variables */
    integer i__, j, ip1, np1;
    doublereal acum;
    integer iback;

/*     ============================================================== */

/*        BACKSOLVE THE N X N UPPER TRIANGULAR SYSTEM A*X = B. */
/*        THE SOLUTION X OVERWRITES THE RIGHT SIDE B. */


    /* Parameter adjustments */
    --x;
    a_dim1 = *ndim;
    a_offset = 1 + a_dim1;
    a -= a_offset;

    /* Function Body */
    x[*n] /= a[*n + *n * a_dim1];
    if (*n == 1) {
   goto L30;
    }
    np1 = *n + 1;
    i__1 = *n;
    for (iback = 2; iback <= i__1; ++iback) {
   i__ = np1 - iback;
/*           I = N-1, N-2, ..., 2, 1 */
   ip1 = i__ + 1;
   acum = x[i__];
   i__2 = *n;
   for (j = ip1; j <= i__2; ++j) {
/* L10: */
       acum -= a[i__ + j * a_dim1] * x[j];
   }
/* L20: */
   x[i__] = acum / a[i__ + i__ * a_dim1];
    }

L30:
    return 0;
} /* bacsub_ */

/*     ============================================================== */
/* Subroutine */ int postpr_(integer *s, integer *l, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer *lnls1, integer 
   *p, doublereal *eps, doublereal *rnorm, doublereal *alf, doublereal *w, 
   doublereal *a, doublereal *b, 
   doublereal *r__, doublereal *u, integer *ierr)
{
    /* System generated locals */
    integer a_dim1, a_offset, b_dim1, b_offset, r_dim1, r_offset, u_dim1, 
       u_offset, i__1, i__2, i__3;
    doublereal d__1;

    /* Local variables */
    integer i__, k, is, kp1, lp1, lnl1;
    doublereal acum;
    integer lpnl, kback;
    real usave;

/*     ============================================================== */

/*        CALCULATE RESIDUALS. */
/*        ON INPUT, U CONTAINS INFORMATION ABOUT HOUSEHOLDER REFLECTIONS */
/*        FROM DPA.  ON OUTPUT, IT CONTAINS THE LINEAR PARAMETERS. */


    /* Parameter adjustments */
    u_dim1 = *l;
    u_offset = 1 + u_dim1;
    u -= u_offset;
    --alf;
    r_dim1 = *n;
    r_offset = 1 + r_dim1;
    r__ -= r_offset;
    --w;
    a_dim1 = *n;
    a_offset = 1 + a_dim1;
    a -= a_offset;
    b_dim1 = *ndim;
    b_offset = 1 + b_dim1;
    b -= b_offset;

    /* Function Body */
    lp1 = *l + 1;
    lpnl = *lnls1 - 2;
    lnl1 = lpnl + 1;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L10: */
/* Computing 2nd power */
   d__1 = w[i__];
   w[i__] = d__1 * d__1;
    }

/*              UNWIND HOUSEHOLDER TRANSFORMATIONS TO GET RESIDUALS, */
/*              AND MOVE THE LINEAR PARAMETERS FROM R TO U. */

    if (*l == 0) {
   goto L30;
    }
    usave = (float)2.;
    i__1 = *l;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L19: */
   b[i__ + (integer) usave * b_dim1] = u[i__ + u_dim1];
    }
    i__1 = *s;
    for (is = 1; is <= i__1; ++is) {
   i__2 = *l;
   for (kback = 1; kback <= i__2; ++kback) {
       k = lp1 - kback;
       kp1 = k + 1;
       acum = (float)0.;
       i__3 = *n;
       for (i__ = kp1; i__ <= i__3; ++i__) {
/* L20: */
      acum += a[i__ + k * a_dim1] * r__[i__ + is * r_dim1];
       }
       u[k + is * u_dim1] = r__[k + is * r_dim1];
       r__[k + is * r_dim1] = acum / a[k + k * a_dim1];
       acum = -acum / (a[k + (integer) usave * a_dim1] * a[k + k * 
          a_dim1]);
       i__3 = *n;
       for (i__ = kp1; i__ <= i__3; ++i__) {
/* L25: */
      r__[i__ + is * r_dim1] -= a[i__ + k * a_dim1] * acum;
       }
   }
    }

L30:
/*  30 IF (IPRINT .LT. 0) GO TO 99 */
/*     WRITE (OUTPUT, 209) */
/*     IF (L .EQ. 0) GO TO 50 */
/*        WRITE(OUTPUT,210) */
/*        DO 40 I=1,L */
/*  40      WRITE(OUTPUT,212) (U(I,J), J=1,S) */
/*  40      CONTINUE */
/*  50 IF (NL .GT. 0) WRITE (OUTPUT, 211) (ALF(K), K = 1, NL) */
/*     WRITE(OUTPUT,214) RNORM */
/*     WRITE (OUTPUT, 209) */
/* L99: */
    return 0;

/* L209: */
/* L210: */
/* L211: */
/* L212: */
/* L214: */
} /* postpr_ */


#ifdef __cplusplus
   }
#endif

