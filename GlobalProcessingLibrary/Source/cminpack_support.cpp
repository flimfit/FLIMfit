
#include <cmath>
#include <algorithm>
#include "cminpack.h"
#include "omp_stub.h"
#include "xmmintrin.h"

using namespace std;


/* Subroutine */ void qrsolv(int n, double *r, int ldr, 
	const int *ipvt, const double *diag, const double *qtb, double *x, 
	double *sdiag, double *wa)
{
    /* Initialized data */

#define p5 .5
#define p25 .25

    /* Local variables */
    int i, j, k, l, jp1, kp1;
    double tan, cos, sin, sum, temp, cotan;
    int nsing;
    double qtbpj;

/*     ********** */

/*     subroutine qrsolv */

/*     given an m by n matrix a, an n by n diagonal matrix d, */
/*     and an m-vector b, the problem is to determine an x which */
/*     solves the system */

/*           a*x = b ,     d*x = 0 , */

/*     in the least squares sense. */

/*     this subroutine completes the solution of the problem */
/*     if it is provided with the necessary information from the */
/*     qr factorization, with column pivoting, of a. that is, if */
/*     a*p = q*r, where p is a permutation matrix, q has orthogonal */
/*     columns, and r is an upper triangular matrix with diagonal */
/*     elements of nonincreasing magnitude, then qrsolv expects */
/*     the full upper triangle of r, the permutation matrix p, */
/*     and the first n components of (q transpose)*b. the system */
/*     a*x = b, d*x = 0, is then equivalent to */

/*                  t       t */
/*           r*z = q *b ,  p *d*p*z = 0 , */

/*     where x = p*z. if this system does not have full rank, */
/*     then a least squares solution is obtained. on output qrsolv */
/*     also provides an upper triangular matrix s such that */

/*            t   t               t */
/*           p *(a *a + d*d)*p = s *s . */

/*     s is computed within qrsolv and may be of separate interest. */

/*     the subroutine statement is */

/*       subroutine qrsolv(n,r,ldr,ipvt,diag,qtb,x,sdiag,wa) */

/*     where */

/*       n is a positive integer input variable set to the order of r. */

/*       r is an n by n array. on input the full upper triangle */
/*         must contain the full upper triangle of the matrix r. */
/*         on output the full upper triangle is unaltered, and the */
/*         strict lower triangle contains the strict upper triangle */
/*         (transposed) of the upper triangular matrix s. */

/*       ldr is a positive integer input variable not less than n */
/*         which specifies the leading dimension of the array r. */

/*       ipvt is an integer input array of length n which defines the */
/*         permutation matrix p such that a*p = q*r. column j of p */
/*         is column ipvt(j) of the identity matrix. */

/*       diag is an input array of length n which must contain the */
/*         diagonal elements of the matrix d. */

/*       qtb is an input array of length n which must contain the first */
/*         n elements of the vector (q transpose)*b. */

/*       x is an output array of length n which contains the least */
/*         squares solution of the system a*x = b, d*x = 0. */

/*       sdiag is an output array of length n which contains the */
/*         diagonal elements of the upper triangular matrix s. */

/*       wa is a work array of length n. */

/*     subprograms called */

/*       fortran-supplied ... dabs,dsqrt */

/*     argonne national laboratory. minpack project. march 1980. */
/*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

/*     ********** */

/*     copy r and (q transpose)*b to preserve input and initialize s. */
/*     in particular, save the diagonal elements of r in x. */

    for (j = 0; j < n; ++j) {
	for (i = j; i < n; ++i) {
	    r[i + j * ldr] = r[j + i * ldr];
	}
	x[j] = r[j + j * ldr];
	wa[j] = qtb[j];
    }

/*     eliminate the diagonal matrix d using a givens rotation. */

    for (j = 0; j < n; ++j) {

/*        prepare the row of d to be eliminated, locating the */
/*        diagonal element using p from the qr factorization. */

	l = ipvt[j]-1;
	if (diag[l] != 0.) {
            for (k = j; k < n; ++k) {
                sdiag[k] = 0.;
            }
            sdiag[j] = diag[l];

/*        the transformations to eliminate the row of d */
/*        modify only a single element of (q transpose)*b */
/*        beyond the first n, which is initially zero. */

            qtbpj = 0.;
            for (k = j; k < n; ++k) {

/*           determine a givens rotation which eliminates the */
/*           appropriate element in the current row of d. */

                if (sdiag[k] != 0.) {
                    if (fabs(r[k + k * ldr]) < fabs(sdiag[k])) {
                        cotan = r[k + k * ldr] / sdiag[k];
                        sin = p5 / sqrt(p25 + p25 * (cotan * cotan));
                        cos = sin * cotan;
                    } else {
                        tan = sdiag[k] / r[k + k * ldr];
                        cos = p5 / sqrt(p25 + p25 * (tan * tan));
                        sin = cos * tan;
                    }

/*           compute the modified diagonal element of r and */
/*           the modified element of ((q transpose)*b,0). */

                    r[k + k * ldr] = cos * r[k + k * ldr] + sin * sdiag[k];
                    temp = cos * wa[k] + sin * qtbpj;
                    qtbpj = -sin * wa[k] + cos * qtbpj;
                    wa[k] = temp;

/*           accumulate the tranformation in the row of s. */

                    kp1 = k + 1;
                    if (n > kp1) {
                        for (i = kp1; i < n; ++i) {
                            temp = cos * r[i + k * ldr] + sin * sdiag[i];
                            sdiag[i] = -sin * r[i + k * ldr] + cos * sdiag[i];
                            r[i + k * ldr] = temp;
                        }
                    }
                }
            }
        }

/*        store the diagonal element of s and restore */
/*        the corresponding diagonal element of r. */

	sdiag[j] = r[j + j * ldr];
	r[j + j * ldr] = x[j];
    }

/*     solve the triangular system for z. if the system is */
/*     singular, then obtain a least squares solution. */

    nsing = n;
    for (j = 0; j < n; ++j) {
	if (sdiag[j] == 0. && nsing == n) {
	    nsing = j;
	}
	if (nsing < n) {
	    wa[j] = 0.;
	}
    }
    if (nsing >= 1) {
        for (k = 1; k <= nsing; ++k) {
            j = nsing - k;
            sum = 0.;
            jp1 = j + 1;
            if (nsing > jp1) {
                for (i = jp1; i < nsing; ++i) {
                    sum += r[i + j * ldr] * wa[i];
                }
            }
            wa[j] = (wa[j] - sum) / sdiag[j];
        }
    }

/*     permute the components of z back to components of x. */

    for (j = 0; j < n; ++j) {
	l = ipvt[j]-1;
	x[l] = wa[j];
    }
    return;

/*     last card of subroutine qrsolv. */

} /* qrsolv_ */


void SSESqrt( float *pOut, float *pIn )
{
   _mm_store_ss( pOut, _mm_rsqrt_ss( _mm_load_ss( pIn ) ) );
   // compiles to movss, sqrtss, movss
}

float Q_rsqrt( float number )
{
  long i;
  float x2, y;
  const float threehalfs = 1.5F;

  x2 = number * 0.5F;
  y  = number;
  i  = * ( long * ) &y;  // evil floating point bit level hacking
  i  = 0x5f3759df - ( i >> 1 ); // what the fuck?
  y  = * ( float * ) &i;
  y  = y * ( threehalfs - ( x2 * y * y ) ); // 1st iteration
  y  = y * ( threehalfs - ( x2 * y * y ) ); // 2nd iteration, this can be removed

  #ifndef Q3_VM
  #ifdef __linux__
    assert( !isnan(y) ); // bk010122 - FPE?
  #endif
  #endif
  return y;
}


/* Subroutine */ void rwupdt(int n, double *r, int ldr, 
	const double *w, double *b, double *alpha, double *cos, 
	double *sin)
{
    /* Initialized data */

#define p5 .5
#define p25 .25

    /* System generated locals */
    int r_dim1, r_offset;

    /* Local variables */


/*     ********** */

/*     subroutine rwupdt */

/*     given an n by n upper triangular matrix r, this subroutine */
/*     computes the qr decomposition of the matrix formed when a row */
/*     is added to r. if the row is specified by the vector w, then */
/*     rwupdt determines an orthogonal matrix q such that when the */
/*     n+1 by n matrix composed of r augmented by w is premultiplied */
/*     by (q transpose), the resulting matrix is upper trapezoidal. */
/*     the matrix (q transpose) is the product of n transformations */

/*           g(n)*g(n-1)* ... *g(1) */

/*     where g(i) is a givens rotation in the (i,n+1) plane which */
/*     eliminates elements in the (n+1)-st plane. rwupdt also */
/*     computes the product (q transpose)*c where c is the */
/*     (n+1)-vector (b,alpha). q itself is not accumulated, rather */
/*     the information to recover the g rotations is supplied. */

/*     the subroutine statement is */

/*       subroutine rwupdt(n,r,ldr,w,b,alpha,cos,sin) */

/*     where */

/*       n is a positive integer input variable set to the order of r. */

/*       r is an n by n array. on input the upper triangular part of */
/*         r must contain the matrix to be updated. on output r */
/*         contains the updated triangular matrix. */

/*       ldr is a positive integer input variable not less than n */
/*         which specifies the leading dimension of the array r. */

/*       w is an input array of length n which must contain the row */
/*         vector to be added to r. */

/*       b is an array of length n. on input b must contain the */
/*         first n elements of the vector c. on output b contains */
/*         the first n elements of the vector (q transpose)*c. */

/*       alpha is a variable. on input alpha must contain the */
/*         (n+1)-st element of the vector c. on output alpha contains */
/*         the (n+1)-st element of the vector (q transpose)*c. */

/*       cos is an output array of length n which contains the */
/*         cosines of the transforming givens rotations. */

/*       sin is an output array of length n which contains the */
/*         sines of the transforming givens rotations. */

/*     subprograms called */

/*       fortran-supplied ... dabs,dsqrt */

/*     argonne national laboratory. minpack project. march 1980. */
/*     burton s. garbow, dudley v. goetschel, kenneth e. hillstrom, */
/*     jorge j. more */

/*     ********** */
    /* Parameter adjustments */
   int j;
  
   --sin;
   --cos;
   --b;
   --w;
   r_dim1 = ldr;
   r_offset = 1 + r_dim1 * 1;
   r -= r_offset;

    /* Function Body */

   for (j = 1; j <= n; ++j) 
   {
      int jm1, i;
      double tan, temp, rowj, cotan;
      rowj = w[j];
      jm1 = j - 1;

//   apply the previous transformations to 
//    r(i,j), i=1,2,...,j-1, and to w(j). 
      
      if (jm1 >= 1) 
      {
         for (i = 1; i <= jm1; ++i) 
         {
            temp = cos[i] * r[i + j * r_dim1] + sin[i] * rowj;
            rowj = -sin[i] * r[i + j * r_dim1] + cos[i] * rowj;
            r[i + j * r_dim1] = temp;
         }
      }
      
//    determine a givens rotation which eliminates w(j). */

      cos[j] = 1.;
      sin[j] = 0.;
	   if (rowj != 0.) 
      {
         if (fabs(r[j + j * r_dim1]) < fabs(rowj)) 
         {
            cotan = r[j + j * r_dim1] / rowj;
            sin[j] = p5 / sqrt(p25 + p25 * (cotan * cotan));
            cos[j] = sin[j] * cotan;
         } else {
            tan = rowj / r[j + j * r_dim1];
            cos[j] = p5 / sqrt(p25 + p25 * (tan * tan));
            sin[j] = cos[j] * tan;
         }

/*       apply the current transformation to r(j,j), b(j), and alpha. */

         r[j + j * r_dim1] = cos[j] * r[j + j * r_dim1] + sin[j] * rowj;
         temp = cos[j] * b[j] + sin[j] * *alpha;
         *alpha = -sin[j] * b[j] + cos[j] * *alpha;
         b[j] = temp;
      }
   }

/*     last card of subroutine rwupdt. */

} /* rwupdt_ */



/* Subroutine */ void qrfac(int m, int n, double *a, int
	lda, int pivot, int *ipvt, int lipvt, double *rdiag,
	 double *acnorm, double *wa)
{
    /* Initialized data */

#define p05 .05

    /* System generated locals */
    double d1;

    /* Local variables */
    int i, j, k, jp1;
    double sum;
    double temp;
    int minmn;
    double epsmch;
    double ajnorm;

/*     ********** */

/*     subroutine qrfac */

/*     this subroutine uses householder transformations with column */
/*     pivoting (optional) to compute a qr factorization of the */
/*     m by n matrix a. that is, qrfac determines an orthogonal */
/*     matrix q, a permutation matrix p, and an upper trapezoidal */
/*     matrix r with diagonal elements of nonincreasing magnitude, */
/*     such that a*p = q*r. the householder transformation for */
/*     column k, k = 1,2,...,min(m,n), is of the form */

/*                           t */
/*           i - (1/u(k))*u*u */

/*     where u has zeros in the first k-1 positions. the form of */
/*     this transformation and the method of pivoting first */
/*     appeared in the corresponding linpack subroutine. */

/*     the subroutine statement is */

/*       subroutine qrfac(m,n,a,lda,pivot,ipvt,lipvt,rdiag,acnorm,wa) */

/*     where */

/*       m is a positive integer input variable set to the number */
/*         of rows of a. */

/*       n is a positive integer input variable set to the number */
/*         of columns of a. */

/*       a is an m by n array. on input a contains the matrix for */
/*         which the qr factorization is to be computed. on output */
/*         the strict upper trapezoidal part of a contains the strict */
/*         upper trapezoidal part of r, and the lower trapezoidal */
/*         part of a contains a factored form of q (the non-trivial */
/*         elements of the u vectors described above). */

/*       lda is a positive integer input variable not less than m */
/*         which specifies the leading dimension of the array a. */

/*       pivot is a logical input variable. if pivot is set true, */
/*         then column pivoting is enforced. if pivot is set false, */
/*         then no column pivoting is done. */

/*       ipvt is an integer output array of length lipvt. ipvt */
/*         defines the permutation matrix p such that a*p = q*r. */
/*         column j of p is column ipvt(j) of the identity matrix. */
/*         if pivot is false, ipvt is not referenced. */

/*       lipvt is a positive integer input variable. if pivot is false, */
/*         then lipvt may be as small as 1. if pivot is true, then */
/*         lipvt must be at least n. */

/*       rdiag is an output array of length n which contains the */
/*         diagonal elements of r. */

/*       acnorm is an output array of length n which contains the */
/*         norms of the corresponding columns of the input matrix a. */
/*         if this information is not needed, then acnorm can coincide */
/*         with rdiag. */

/*       wa is a work array of length n. if pivot is false, then wa */
/*         can coincide with rdiag. */

/*     subprograms called */

/*       minpack-supplied ... dpmpar,enorm */

/*       fortran-supplied ... dmax1,dsqrt,min0 */

/*     argonne national laboratory. minpack project. march 1980. */
/*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

/*     ********** */

/*     epsmch is the machine precision. */

    epsmch = dpmpar(1);

/*     compute the initial column norms and initialize several arrays. */

    for (j = 0; j < n; ++j) {
	acnorm[j] = enorm(m, &a[j * lda + 0]);
	rdiag[j] = acnorm[j];
	wa[j] = rdiag[j];
	if (pivot) {
	    ipvt[j] = j+1;
	}
    }

/*     reduce a to r with householder transformations. */

    minmn = min(m,n);
    for (j = 0; j < minmn; ++j) {
	if (pivot) {

/*        bring the column of largest norm into the pivot position. */

            int kmax = j;
            for (k = j; k < n; ++k) {
                if (rdiag[k] > rdiag[kmax]) {
                    kmax = k;
                }
            }
            if (kmax != j) {
                for (i = 0; i < m; ++i) {
                    temp = a[i + j * lda];
                    a[i + j * lda] = a[i + kmax * lda];
                    a[i + kmax * lda] = temp;
                }
                rdiag[kmax] = rdiag[j];
                wa[kmax] = wa[j];
                k = ipvt[j];
                ipvt[j] = ipvt[kmax];
                ipvt[kmax] = k;
            }
        }

/*        compute the householder transformation to reduce the */
/*        j-th column of a to a multiple of the j-th unit vector. */

	ajnorm = enorm(m - (j+1) + 1, &a[j + j * lda]);
	if (ajnorm != 0.) {
            if (a[j + j * lda] < 0.) {
                ajnorm = -ajnorm;
            }
            for (i = j; i < m; ++i) {
                a[i + j * lda] /= ajnorm;
            }
            a[j + j * lda] += 1.;

/*        apply the transformation to the remaining columns */
/*        and update the norms. */

            jp1 = j + 1;
            if (n > jp1) {
                for (k = jp1; k < n; ++k) {
                    sum = 0.;
                    for (i = j; i < m; ++i) {
                        sum += a[i + j * lda] * a[i + k * lda];
                    }
                    temp = sum / a[j + j * lda];
                    for (i = j; i < m; ++i) {
                        a[i + k * lda] -= temp * a[i + j * lda];
                    }
                    if (pivot && rdiag[k] != 0.) {
                        temp = a[j + k * lda] / rdiag[k];
                        /* Computing MAX */
                        d1 = 1. - temp * temp;
                        rdiag[k] *= sqrt((max(0.,d1)));
                        /* Computing 2nd power */
                        d1 = rdiag[k] / wa[k];
                        if (p05 * (d1 * d1) <= epsmch) {
                            rdiag[k] = enorm(m - (j+1), &a[jp1 + k * lda]);
                            wa[k] = rdiag[k];
                        }
                    }
                }
            }
        }
	rdiag[j] = -ajnorm;
    }

/*     last card of subroutine qrfac. */

} /* qrfac_ */



/* Subroutine */ void lmpar(int n, double *r, int ldr, 
	const int *ipvt, const double *diag, const double *qtb, double delta, 
	double *par, double *x, double *sdiag, double *wa1, 
	double *wa2)
{
    /* Initialized data */

#define p1 .1
#define p001 .001

    /* System generated locals */
    double d1, d2;

    /* Local variables */
    int i, j, k, l;
    double fp;
    double sum, parc, parl;
    int iter;
    double temp, paru, dwarf;
    int nsing;
    double gnorm;
    double dxnorm;

/*     ********** */

/*     subroutine lmpar */

/*     given an m by n matrix a, an n by n nonsingular diagonal */
/*     matrix d, an m-vector b, and a positive number delta, */
/*     the problem is to determine a value for the parameter */
/*     par such that if x solves the system */

/*           a*x = b ,     sqrt(par)*d*x = 0 , */

/*     in the least squares sense, and dxnorm is the euclidean */
/*     norm of d*x, then either par is zero and */

/*           (dxnorm-delta) .le. 0.1*delta , */

/*     or par is positive and */

/*           abs(dxnorm-delta) .le. 0.1*delta . */

/*     this subroutine completes the solution of the problem */
/*     if it is provided with the necessary information from the */
/*     qr factorization, with column pivoting, of a. that is, if */
/*     a*p = q*r, where p is a permutation matrix, q has orthogonal */
/*     columns, and r is an upper triangular matrix with diagonal */
/*     elements of nonincreasing magnitude, then lmpar expects */
/*     the full upper triangle of r, the permutation matrix p, */
/*     and the first n components of (q transpose)*b. on output */
/*     lmpar also provides an upper triangular matrix s such that */

/*            t   t                   t */
/*           p *(a *a + par*d*d)*p = s *s . */

/*     s is employed within lmpar and may be of separate interest. */

/*     only a few iterations are generally needed for convergence */
/*     of the algorithm. if, however, the limit of 10 iterations */
/*     is reached, then the output par will contain the best */
/*     value obtained so far. */

/*     the subroutine statement is */

/*       subroutine lmpar(n,r,ldr,ipvt,diag,qtb,delta,par,x,sdiag, */
/*                        wa1,wa2) */

/*     where */

/*       n is a positive integer input variable set to the order of r. */

/*       r is an n by n array. on input the full upper triangle */
/*         must contain the full upper triangle of the matrix r. */
/*         on output the full upper triangle is unaltered, and the */
/*         strict lower triangle contains the strict upper triangle */
/*         (transposed) of the upper triangular matrix s. */

/*       ldr is a positive integer input variable not less than n */
/*         which specifies the leading dimension of the array r. */

/*       ipvt is an integer input array of length n which defines the */
/*         permutation matrix p such that a*p = q*r. column j of p */
/*         is column ipvt(j) of the identity matrix. */

/*       diag is an input array of length n which must contain the */
/*         diagonal elements of the matrix d. */

/*       qtb is an input array of length n which must contain the first */
/*         n elements of the vector (q transpose)*b. */

/*       delta is a positive input variable which specifies an upper */
/*         bound on the euclidean norm of d*x. */

/*       par is a nonnegative variable. on input par contains an */
/*         initial estimate of the levenberg-marquardt parameter. */
/*         on output par contains the final estimate. */

/*       x is an output array of length n which contains the least */
/*         squares solution of the system a*x = b, sqrt(par)*d*x = 0, */
/*         for the output par. */

/*       sdiag is an output array of length n which contains the */
/*         diagonal elements of the upper triangular matrix s. */

/*       wa1 and wa2 are work arrays of length n. */

/*     subprograms called */

/*       minpack-supplied ... dpmpar,enorm,qrsolv */

/*       fortran-supplied ... dabs,dmax1,dmin1,dsqrt */

/*     argonne national laboratory. minpack project. march 1980. */
/*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

/*     ********** */

/*     dwarf is the smallest positive magnitude. */

    dwarf = dpmpar(2);

/*     compute and store in x the gauss-newton direction. if the */
/*     jacobian is rank-deficient, obtain a least squares solution. */

    nsing = n;
    for (j = 0; j < n; ++j) {
	wa1[j] = qtb[j];
	if (r[j + j * ldr] == 0. && nsing == n) {
	    nsing = j;
	}
	if (nsing < n) {
	    wa1[j] = 0.;
	}
/* L10: */
    }
    if (nsing >= 1) {
        for (k = 1; k <= nsing; ++k) {
            j = nsing - k;
            wa1[j] /= r[j + j * ldr];
            temp = wa1[j];
            if (j >= 1) {
                for (i = 0; i < j; ++i) {
                    wa1[i] -= r[i + j * ldr] * temp;
                }
            }
        }
    }
    for (j = 0; j < n; ++j) {
	l = ipvt[j]-1;
	x[l] = wa1[j];
    }

/*     initialize the iteration counter. */
/*     evaluate the function at the origin, and test */
/*     for acceptance of the gauss-newton direction. */

    iter = 0;
    for (j = 0; j < n; ++j) {
	wa2[j] = diag[j] * x[j];
    }
    dxnorm = enorm(n, wa2);
    fp = dxnorm - delta;
    if (fp <= p1 * delta) {
	goto TERMINATE;
    }

/*     if the jacobian is not rank deficient, the newton */
/*     step provides a lower bound, parl, for the zero of */
/*     the function. otherwise set this bound to zero. */

    parl = 0.;
    if (nsing >= n) {
        for (j = 0; j < n; ++j) {
            l = ipvt[j]-1;
            wa1[j] = diag[l] * (wa2[l] / dxnorm);
        }
        for (j = 0; j < n; ++j) {
            sum = 0.;
            if (j >= 1) {
                for (i = 0; i < j; ++i) {
                    sum += r[i + j * ldr] * wa1[i];
                }
            }
            wa1[j] = (wa1[j] - sum) / r[j + j * ldr];
        }
        temp = enorm(n, wa1);
        parl = fp / delta / temp / temp;
    }

/*     calculate an upper bound, paru, for the zero of the function. */

    for (j = 0; j < n; ++j) {
	sum = 0.;
	for (i = 0; i <= j; ++i) {
	    sum += r[i + j * ldr] * qtb[i];
	}
	l = ipvt[j]-1;
	wa1[j] = sum / diag[l];
    }
    gnorm = enorm(n, wa1);
    paru = gnorm / delta;
    if (paru == 0.) {
	paru = dwarf / min(delta,p1);
    }

/*     if the input par lies outside of the interval (parl,paru), */
/*     set par to the closer endpoint. */

    *par = max(*par,parl);
    *par = min(*par,paru);
    if (*par == 0.) {
	*par = gnorm / dxnorm;
    }

/*     beginning of an iteration. */

    for (;;) {
        ++iter;

/*        evaluate the function at the current value of par. */

        if (*par == 0.) {
            /* Computing MAX */
            d1 = dwarf, d2 = p001 * paru;
            *par = max(d1,d2);
        }
        temp = sqrt(*par);
        for (j = 0; j < n; ++j) {
            wa1[j] = temp * diag[j];
        }
        qrsolv(n, r, ldr, ipvt, wa1, qtb, x, sdiag, wa2);
        for (j = 0; j < n; ++j) {
            wa2[j] = diag[j] * x[j];
        }
        dxnorm = enorm(n, wa2);
        temp = fp;
        fp = dxnorm - delta;

/*        if the function is small enough, accept the current value */
/*        of par. also test for the exceptional cases where parl */
/*        is zero or the number of iterations has reached 10. */

        if (fabs(fp) <= p1 * delta || (parl == 0. && fp <= temp && temp < 0.) || iter == 10) {
            goto TERMINATE;
        }

/*        compute the newton correction. */

        for (j = 0; j < n; ++j) {
            l = ipvt[j]-1;
            wa1[j] = diag[l] * (wa2[l] / dxnorm);
        }
        for (j = 0; j < n; ++j) {
            wa1[j] /= sdiag[j];
            temp = wa1[j];
            if (n > j+1) {
                for (i = j+1; i < n; ++i) {
                    wa1[i] -= r[i + j * ldr] * temp;
                }
            }
        }
        temp = enorm(n, wa1);
        parc = fp / delta / temp / temp;

/*        depending on the sign of the function, update parl or paru. */

        if (fp > 0.) {
            parl = max(parl,*par);
        }
        if (fp < 0.) {
            paru = min(paru,*par);
        }

/*        compute an improved estimate for par. */

        /* Computing MAX */
        d1 = parl, d2 = *par + parc;
        *par = max(d1,d2);

/*        end of an iteration. */

    }
TERMINATE:

/*     termination. */

    if (iter == 0) {
	*par = 0.;
    }

/*     last card of subroutine lmpar. */

} /* lmpar_ */



double dpmpar(int i)
{
    /* Initialized data */

    static struct {
	double e_1[3];
	double fill_2[1];
	} equiv_2 = { { 2.22044604926e-16, 2.22507385852e-308, 
                        1.79769313485e308 }, { 0. } };


    /* System generated locals */
    double ret_val;

    /* Local variables */
#define dmach ((double *)&equiv_2)
#define minmag ((int *)&equiv_2 + 2)
#define maxmag ((int *)&equiv_2 + 4)
#define mcheps ((int *)&equiv_2)

/*     ********** */

/*     Function dpmpar */

/*     This function provides double precision machine parameters */
/*     when the appropriate set of data statements is activated (by */
/*     removing the c from column 1) and all other data statements are */
/*     rendered inactive. Most of the parameter values were obtained */
/*     from the corresponding Bell Laboratories Port Library function. */

/*     The function statement is */

/*       double precision function dpmpar(i) */

/*     where */

/*       i is an integer input variable set to 1, 2, or 3 which */
/*         selects the desired machine parameter. If the machine has */
/*         t base b digits and its smallest and largest exponents are */
/*         emin and emax, respectively, then these parameters are */

/*         dpmpar(1) = b**(1 - t), the machine precision, */

/*         dpmpar(2) = b**(emin - 1), the smallest magnitude, */

/*         dpmpar(3) = b**emax*(1 - b**(-t)), the largest magnitude. */

/*     Argonne National Laboratory. MINPACK Project. November 1996. */
/*     Burton S. Garbow, Kenneth E. Hillstrom, Jorge J. More' */

/*     ********** */

/*     Machine constants for the IBM 360/370 series, */
/*     the Amdahl 470/V6, the ICL 2900, the Itel AS/6, */
/*     the Xerox Sigma 5/7/9 and the Sel systems 85/86. */

/*     data mcheps(1),mcheps(2) / z34100000, z00000000 / */
/*     data minmag(1),minmag(2) / z00100000, z00000000 / */
/*     data maxmag(1),maxmag(2) / z7fffffff, zffffffff / */

/*     Machine constants for the Honeywell 600/6000 series. */

/*     data mcheps(1),mcheps(2) / o606400000000, o000000000000 / */
/*     data minmag(1),minmag(2) / o402400000000, o000000000000 / */
/*     data maxmag(1),maxmag(2) / o376777777777, o777777777777 / */

/*     Machine constants for the CDC 6000/7000 series. */

/*     data mcheps(1) / 15614000000000000000b / */
/*     data mcheps(2) / 15010000000000000000b / */

/*     data minmag(1) / 00604000000000000000b / */
/*     data minmag(2) / 00000000000000000000b / */

/*     data maxmag(1) / 37767777777777777777b / */
/*     data maxmag(2) / 37167777777777777777b / */

/*     Machine constants for the PDP-10 (KA processor). */

/*     data mcheps(1),mcheps(2) / "114400000000, "000000000000 / */
/*     data minmag(1),minmag(2) / "033400000000, "000000000000 / */
/*     data maxmag(1),maxmag(2) / "377777777777, "344777777777 / */

/*     Machine constants for the PDP-10 (KI processor). */

/*     data mcheps(1),mcheps(2) / "104400000000, "000000000000 / */
/*     data minmag(1),minmag(2) / "000400000000, "000000000000 / */
/*     data maxmag(1),maxmag(2) / "377777777777, "377777777777 / */

/*     Machine constants for the PDP-11. */

/*     data mcheps(1),mcheps(2) /   9472,      0 / */
/*     data mcheps(3),mcheps(4) /      0,      0 / */

/*     data minmag(1),minmag(2) /    128,      0 / */
/*     data minmag(3),minmag(4) /      0,      0 / */

/*     data maxmag(1),maxmag(2) /  32767,     -1 / */
/*     data maxmag(3),maxmag(4) /     -1,     -1 / */

/*     Machine constants for the Burroughs 6700/7700 systems. */

/*     data mcheps(1) / o1451000000000000 / */
/*     data mcheps(2) / o0000000000000000 / */

/*     data minmag(1) / o1771000000000000 / */
/*     data minmag(2) / o7770000000000000 / */

/*     data maxmag(1) / o0777777777777777 / */
/*     data maxmag(2) / o7777777777777777 / */

/*     Machine constants for the Burroughs 5700 system. */

/*     data mcheps(1) / o1451000000000000 / */
/*     data mcheps(2) / o0000000000000000 / */

/*     data minmag(1) / o1771000000000000 / */
/*     data minmag(2) / o0000000000000000 / */

/*     data maxmag(1) / o0777777777777777 / */
/*     data maxmag(2) / o0007777777777777 / */

/*     Machine constants for the Burroughs 1700 system. */

/*     data mcheps(1) / zcc6800000 / */
/*     data mcheps(2) / z000000000 / */

/*     data minmag(1) / zc00800000 / */
/*     data minmag(2) / z000000000 / */

/*     data maxmag(1) / zdffffffff / */
/*     data maxmag(2) / zfffffffff / */

/*     Machine constants for the Univac 1100 series. */

/*     data mcheps(1),mcheps(2) / o170640000000, o000000000000 / */
/*     data minmag(1),minmag(2) / o000040000000, o000000000000 / */
/*     data maxmag(1),maxmag(2) / o377777777777, o777777777777 / */

/*     Machine constants for the Data General Eclipse S/200. */

/*     Note - it may be appropriate to include the following card - */
/*     static dmach(3) */

/*     data minmag/20k,3*0/,maxmag/77777k,3*177777k/ */
/*     data mcheps/32020k,3*0/ */

/*     Machine constants for the Harris 220. */

/*     data mcheps(1),mcheps(2) / '20000000, '00000334 / */
/*     data minmag(1),minmag(2) / '20000000, '00000201 / */
/*     data maxmag(1),maxmag(2) / '37777777, '37777577 / */

/*     Machine constants for the Cray-1. */

/*     data mcheps(1) / 0376424000000000000000b / */
/*     data mcheps(2) / 0000000000000000000000b / */

/*     data minmag(1) / 0200034000000000000000b / */
/*     data minmag(2) / 0000000000000000000000b / */

/*     data maxmag(1) / 0577777777777777777777b / */
/*     data maxmag(2) / 0000007777777777777776b / */

/*     Machine constants for the Prime 400. */

/*     data mcheps(1),mcheps(2) / :10000000000, :00000000123 / */
/*     data minmag(1),minmag(2) / :10000000000, :00000100000 / */
/*     data maxmag(1),maxmag(2) / :17777777777, :37777677776 / */

/*     Machine constants for the VAX-11. */

/*     data mcheps(1),mcheps(2) /   9472,  0 / */
/*     data minmag(1),minmag(2) /    128,  0 / */
/*     data maxmag(1),maxmag(2) / -32769, -1 / */

/*     Machine constants for IEEE machines. */


    ret_val = dmach[(0 + (0 + ((i - 1) << 3))) / 8];
    return ret_val;

/*     Last card of function dpmpar. */

} /* dpmpar_ */

#undef mcheps
#undef maxmag
#undef minmag
#undef dmach



double enorm(int n, const double *x)
{
    /* Initialized data */

#define rdwarf 3.834e-20
#define rgiant 1.304e19

    /* System generated locals */
    double ret_val, d1;

    /* Local variables */
    int i;
    double s1, s2, s3, xabs, x1max, x3max, agiant, floatn;

/*     ********** */

/*     function enorm */

/*     given an n-vector x, this function calculates the */
/*     euclidean norm of x. */

/*     the euclidean norm is computed by accumulating the sum of */
/*     squares in three different sums. the sums of squares for the */
/*     small and large components are scaled so that no overflows */
/*     occur. non-destructive underflows are permitted. underflows */
/*     and overflows do not occur in the computation of the unscaled */
/*     sum of squares for the intermediate components. */
/*     the definitions of small, intermediate and large components */
/*     depend on two constants, rdwarf and rgiant. the main */
/*     restrictions on these constants are that rdwarf**2 not */
/*     underflow and rgiant**2 not overflow. the constants */
/*     given here are suitable for every known computer. */

/*     the function statement is */

/*       double precision function enorm(n,x) */

/*     where */

/*       n is a positive integer input variable. */

/*       x is an input array of length n. */

/*     subprograms called */

/*       fortran-supplied ... dabs,dsqrt */

/*     argonne national laboratory. minpack project. march 1980. */
/*     burton s. garbow, kenneth e. hillstrom, jorge j. more */

/*     ********** */

    s1 = 0.;
    s2 = 0.;
    s3 = 0.;
    x1max = 0.;
    x3max = 0.;
    floatn = (double) (n);
    agiant = rgiant / floatn;
    for (i = 0; i < n; ++i) {
	xabs = fabs(x[i]);
	if (xabs <= rdwarf || xabs >= agiant) {
            if (xabs > rdwarf) {

/*              sum for large components. */

                if (xabs > x1max) {
                    /* Computing 2nd power */
                    d1 = x1max / xabs;
                    s1 = 1. + s1 * (d1 * d1);
                    x1max = xabs;
                } else {
                    /* Computing 2nd power */
                    d1 = xabs / x1max;
                    s1 += d1 * d1;
                }
            } else {

/*              sum for small components. */

                if (xabs > x3max) {
                    /* Computing 2nd power */
                    d1 = x3max / xabs;
                    s3 = 1. + s3 * (d1 * d1);
                    x3max = xabs;
                } else {
                    if (xabs != 0.) {
                        /* Computing 2nd power */
                        d1 = xabs / x3max;
                        s3 += d1 * d1;
                    }
                }
            }
	} else {

/*           sum for intermediate components. */

            /* Computing 2nd power */
            s2 += xabs * xabs;
        }
    }

/*     calculation of norm. */

    if (s1 != 0.) {
        ret_val = x1max * sqrt(s1 + (s2 / x1max) / x1max);
    } else {
        if (s2 != 0.) {
            if (s2 >= x3max) {
                ret_val = sqrt(s2 * (1. + (x3max / s2) * (x3max * s3)));
            } else {
                ret_val = sqrt(x3max * ((s2 / x3max) + (x3max * s3)));
            }
        } else {
            ret_val = x3max * sqrt(s3);
        }
    }
    return ret_val;

/*     last card of function enorm. */

} /* enorm_ */

