#include "ModelADA.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "f2c.h"



/* Table of constant values */

static integer c__1 = 1;
static integer c__3 = 3;

/*     ============================================================== */
/* Subroutine */ int dpa_(integer *s, integer *l, integer *lmax, integer *nl, 
	integer *n, integer *nmax, integer *ndim, integer *lpps1, integer *
	lps, integer *pp2, integer *iv, doublereal *t, doublereal *y, doublereal 
	*w, doublereal *alf, S_fp ada, integer *isel, integer *iprint, 
	doublereal *a, doublereal *b, doublereal *u, doublereal *r__, 
	doublereal *rnorm, integer *gc, integer *thread, integer *static_store)
{
    /* System generated locals */
    integer a_dim1, a_offset, b_dim1, b_offset, t_dim1, t_offset, r_dim1, 
	 r_offset, y_dim1, y_offset, i__1, i__2, i__3;
    doublereal d__1;

    /* Builtin functions */
    double d_sign(doublereal *, doublereal *), sqrt(doublereal);

    //static integer static_store[200];

    integer& lp1 = static_store[0];
    integer& ncon = static_store[1];
    integer& philp1 = static_store[2];
    integer& nconp1 = static_store[3];
    integer& nowate = static_store[4];

    integer* inc = static_store + 5;

    /*
    static integer lp1, inc[96];
    static integer ncon;
    static logical philp1;
    static integer nconp1;
    static logical nowate;
    */

    /* Local variables */
    integer i__, j, k, m, p;
    integer is, kp1;
    integer lsp1;
    doublereal beta, acum;
    doublereal save;
    integer isub;
    extern /* Subroutine */ int init_(integer *s, integer *l, integer *lmax, integer *nl,
	 integer *n, integer *nmax, integer *ndim, integer *lpps1, integer *
	lps, integer *pp2, integer *iv, doublereal *t, doublereal *w, 
	doublereal *alf, S_fp ada, integer *isel, integer *iprint, doublereal 
	*a, doublereal *b, integer *inc, integer *ncon, integer *nconp1, 
	logical *philp1, logical *nowate, integer *gc, integer *thread);
    integer ksub, lnls, lpps, lnls1;
    doublereal alpha;
    extern doublereal xnorm_(integer *, doublereal *);
    integer isback;
    extern /* Subroutine */ int bacsub_(integer *, integer *, doublereal *, 
	    doublereal *);
    integer lastca, lastcb;
    extern /* Subroutine */ int varerr_(integer *, integer *, integer *);
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

    /* Function Body */
    save = 0.;

    lnls = *l + *nl + *s;
    lnls1 = lnls + 1;
    lsp1 = *l + *s + 1;
    lpps = *lpps1 - 1;
    p = lpps - *l - *s;

    if (*isel != 1) {
	goto L3;
    }
    lp1 = *l + 1;
    firstca = 1;
    lastca = *lps;
    firstcb = 1;
    lastcb = p;
    firstr = lp1;
    init_(s, l, lmax, nl, n, nmax, ndim, lpps1, lps, pp2, iv, &t[t_offset], &
	    w[1], &alf[1], (S_fp)ada, isel, iprint, &a[a_offset], &b[b_offset],
	    inc, &ncon, &nconp1, &philp1, &nowate, gc, thread);
    if (*isel != 1) {
	goto L99;
    }
    goto L30;

L3:
    i__1 = min(*isel,3);
    (*ada)(s, &lp1, nl, n, nmax, ndim, lpps1, pp2, iv, &a[a_offset], &b[
	    b_offset], inc, &t[t_offset], &alf[1], &i__1, gc, thread);
    if (*isel == 2) {
	goto L6;
    }
/*                                                 ISEL = 3 OR 4 */
    firstcb = 1;
    lastcb = p;
    firstca = 0;
    firstr = (4 - *isel) * *l + 1;
    goto L50;
/*                                                 ISEL = 2 */
L6:
    firstca = nconp1;
    lastca = *lps;
    firstcb = 0;
    if (ncon == 0) {
	goto L30;
    }
/*     IF (A(1, NCON) .EQ. SAVE) GO TO 30 */
/*        ISEL = -7 */
/*        CALL VARERR (IPRINT, ISEL, NCON) */
/*        GO TO 99 */
/*                                                  ISEL = 1 OR 2 */
L30:
    if (philp1) {
	goto L40;
    }
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i__2 = *s;
	for (j = 1; j <= i__2; ++j) {
/* L35: */
	    r__[i__ + j * r_dim1] = y[i__ + j * y_dim1];
	}
    }
    goto L50;
L40:

    //------------------------------

      i__2 = *n;
      i__1 = *s;
      //#pragma omp parallel for private(i__)
      for(j=i__1; j > 1; --j)
         for(i__=1; i__ <= i__2; ++i__)
            r__[i__ + j * r_dim1] = y[i__ + j * y_dim1] - r__[i__ + r_dim1];

      for(i__=1; i__ <= i__2; ++i__)
         r__[i__ + r_dim1] = y[i__ + y_dim1] - r__[i__ + r_dim1];

            
    //-------------------------------

   // REPLACING:
/*    i__2 = *n;
    for(i__=1; i__ <= i__2; ++i__)
    {
	   ri = r__[i__ + r_dim1];
	   i__1 = *s;
	   for (j = 1; j <= i__1; ++j) 
      {
	      r__[i__ + j * r_dim1] = y[i__ + j * y_dim1] - ri;    // Profiling: 37%
	   }
    }*/
    
/*                                             WEIGHT APPROPRIATE COLUMNS */
L50:
    if (nowate) {
	goto L60;
    }
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	acum = w[i__];
	if (firstca == 0) {
	    goto L56;
	}
	i__2 = lastca;
   //#pragma omp parallel for
	for (j = firstca; j <= i__2; ++j) {
	    a[i__ + j * a_dim1] *= acum;    //Profiling: 12.1%
	}
L56:
	if (firstcb == 0) {
	    goto L59;
	}
/* L57: */
	i__2 = lastcb;
	for (j = firstcb; j <= i__2; ++j) {
/* L58: */
	    b[i__ + j * b_dim1] *= acum;
	}
L59:
	;
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

L60:
    if (*l == 0) {
	goto L75;
    }
    i__1 = *l;
    for (k = 1; k <= i__1; ++k) {
	kp1 = k + 1;
	if (*isel >= 3 || *isel == 2 && k < nconp1) {
	    goto L61;
	}
	i__2 = *n + 1 - k;
	d__1 = xnorm_(&i__2, &a[k + k * a_dim1]);
	alpha = d_sign(&d__1, &a[k + k * a_dim1]);
	u[k] = a[k + k * a_dim1] + alpha;
	a[k + k * a_dim1] = -alpha;
	firstca = kp1;
	if (alpha != (float)0.) {
	    goto L61;
	}
	*isel = -8;
	varerr_(iprint, isel, &k);
	goto L99;
/*                                        APPLY REFLECTIONS TO COLUMNS */
/*                                        FIRSTC TO LASTC. */
L61:
	beta = -a[k + k * a_dim1] * u[k];

	if (firstca == 0) {
	    goto L64;
	}
	i__2 = lastca;
	for (j = firstca; j <= i__2; ++j) {
	    acum = u[k] * a[k + j * a_dim1];
	    i__3 = *n;
	    for (i__ = kp1; i__ <= i__3; ++i__) {
/* L62: */
		acum += a[i__ + k * a_dim1] * a[i__ + j * a_dim1];
	    }
	    acum /= beta;
	    a[k + j * a_dim1] -= u[k] * acum;
	    i__3 = *n;
	    for (i__ = kp1; i__ <= i__3; ++i__) {
/* L63: */
		a[i__ + j * a_dim1] -= a[i__ + k * a_dim1] * acum;
	    }
	}

L64:
	if (firstcb == 0) {
	    goto L70;
	}
	i__3 = lastcb;
	for (j = firstcb; j <= i__3; ++j) {
	    acum = u[k] * b[k + j * b_dim1];
	    i__2 = *n;
	    for (i__ = kp1; i__ <= i__2; ++i__) {
/* L65: */
		acum += a[i__ + k * a_dim1] * b[i__ + j * b_dim1];
	    }
	    acum /= beta;
	    b[k + j * b_dim1] -= u[k] * acum;
	    i__2 = *n;
	    for (i__ = kp1; i__ <= i__2; ++i__) {
/* L66: */
		b[i__ + j * b_dim1] -= a[i__ + k * a_dim1] * acum;
	    }
	}
L70:
	;
    }


L75:
    if (*isel >= 3) {
	goto L85;
    }

/*           COMPUTE THE FROBENIUS NORM OF THE RESIDUAL MATRIX: */
    *rnorm = (float)0.;
    i__1 = *s;
    for (j = 1; j <= i__1; ++j) {
/* L76: */
	i__2 = *n - *l;
/* Computing 2nd power */
	d__1 = xnorm_(&i__2, &r__[lp1 + j * r_dim1]);
	*rnorm += d__1 * d__1;
    }
    *rnorm = sqrt(*rnorm);

    if (*isel == 2) {
	goto L99;
    }
    if (ncon > 0) {
	save = a[ncon * a_dim1 + 1];
    }

/*           F2 IS NOW CONTAINED IN ROWS L+1 TO N AND COLUMNS L+S+1 TO */
/*           L+P+S OF THE MATRIX A.  NOW SOLVE THE S (L X L) UPPER */
/*           TRIANGULAR SYSTEMS TRI*BETA(J) = R1(J) FOR THE LINEAR */
/*           PARAMETERS BETA.  BETA OVERWRITES R1. */

L85:
    if (*l == 0) {
	goto L87;
    }
    i__2 = *s;
    for (j = 1; j <= i__2; ++j) {
/* L86: */
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

L87:
    i__2 = *n;
    for (i__ = firstr; i__ <= i__2; ++i__) {
	i__1 = *s;
	for (isback = 1; isback <= i__1; ++isback) {
	    is = *s - isback + 1;
	    isub = (*n - *l) * (is - 1) + i__;
	    if (*l == ncon) {
		goto L95;
	    }
	    m = 0;
	    i__3 = *nl;
	    for (k = 1; k <= i__3; ++k) {
		acum = (float)0.;
		for (j = nconp1; j <= *l; ++j) 
      {
		   if (inc[k + j * 12 - 13] != 0) 
         {
			   ++m;
		      acum += b[i__ + m * b_dim1] * r__[j + is * r_dim1];     // Profiling: 11.8%
         }
      }
		ksub = *lps + k;
		if (inc[k + lp1 * 12 - 13] == 0) {
		    goto L90;
		}
		++m;
		acum += b[i__ + m * b_dim1];
L90:
		b[isub + k * b_dim1] = acum;
	    }
L95:
	    b[isub + (*nl + 1) * b_dim1] = r__[i__ + is * r_dim1];
	}
    }
/*   87 DO 95 ISBACK=1,S */
/* 		 IS = S - ISBACK + 1 */
/*         DO 95 I = FIRSTR, N */
/*            IF (L .EQ. NCON) GO TO 95 */
/* 				M = LPS */
/* 				DO 90 K = 1, NL */
/* 					ACUM = 0. */
/* 					DO 88 J = NCONP1, L */
/* 						IF (INC(K, J) .EQ. 0) GO TO 88 */
/* 						M = M + 1 */
/* 						ACUM = ACUM + A(I, M) * R(J,IS) */
/*   88					CONTINUE */
/* 				KSUB = LPS + K */
/* 				IF (INC(K, LP1) .EQ. 0) GO TO 90 */
/* 				M = M + 1 */
/* 				ACUM = ACUM + A(I, M) */
/*   90			A(I, KSUB) = ACUM */
/*   95		A(I, LNLS1) = R(I,IS) */

L99:
    return 0;
} /* dpa_ */

/*     ============================================================== */
doublereal xnorm_(integer *n, doublereal *x)
{
    /* System generated locals */
    integer i__1;
    doublereal ret_val, d__1, d__2;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    integer i__;
    doublereal sum, rmax, term;

/*     ============================================================== */

/*        COMPUTE THE L2 (EUCLIDEAN) NORM OF A VECTOR, MAKING SURE TO */
/*        AVOID UNNECESSARY UNDERFLOWS.  NO ATTEMPT IS MADE TO SUPPRESS */
/*        OVERFLOWS. */


/*           FIND LARGEST (IN ABSOLUTE VALUE) ELEMENT */
    /* Parameter adjustments */
    --x;

    /* Function Body */
    rmax = (float)0.;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if ((d__1 = x[i__], dabs(d__1)) > rmax) {
	    rmax = (d__2 = x[i__], dabs(d__2));
	}
/* L10: */
    }

    sum = (float)0.;
    if (rmax == (float)0.) {
	goto L30;
    }
    i__1 = *n;
    ////#pragma omp parallel reduction (+: sum) private (term)
    for (i__ = 1; i__ <= i__1; ++i__) {
	term = (float)0.;
	if (rmax + (d__1 = x[i__], abs(d__1)) != rmax) {
	    term = x[i__] / rmax;
	}
/* L20: */
	sum += term * term;
    }

L30:
    ret_val = rmax * sqrt(sum);
/* L99: */
    return ret_val;
} /* xnorm_ */



#ifdef __cplusplus
	}
#endif
