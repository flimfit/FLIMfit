/* VarPro.f -- translated by f2c (version 20060506).
   You must link the resulting object file with libf2c:
   on Microsoft Windows system, link with libf2c.lib;
   on Linux or Unix systems, link with .../path/to/libf2c.a -lm
   or, if you install libf2c.a in a standard place, with -lf2c -lm
   -- in that order, at the end of the command line, as in
      cc *.o -lf2c -lm
   Source for libf2c is in /netlib/f2c/libf2c.zip, e.g.,

      http://www.netlib.org/f2c/libf2c.zip
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "f2c.h"

/* Table of constant values */

static integer c__1 = 1;
static integer c__3 = 3;
static integer c__2 = 2;

/*     ============================================================== */
/* Subroutine */ int varp2_(integer *s, integer *l, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer *lpps1, integer 
   *lps, integer *pp2, doublereal *t, doublereal *y, 
   doublereal *w, S_fp ada, doublereal *a, doublereal *b,
   integer *itmax, integer *gc, integer *thread, real *sstore, 
   doublereal *alf, doublereal *beta, integer *ierr, doublereal *r__, 
   integer *gn, doublereal *alfbest)
{
    /* Initialized data */

    static doublereal eps1 = 1e-6;

    /* System generated locals */
    integer a_dim1, a_offset, b_dim1, b_offset, beta_dim1, beta_offset, 
       y_dim1, y_offset, t_dim1, t_offset, i__1, i__2;
    real r__1;
    doublereal d__1;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    integer j, k, b1, terminate;
    doublereal nu;
    integer lp1;
extern
int dpa_(int *s, int *l, int *nl, 
   int *n, int *nmax, int *ndim, int *lpps1, int *
   lps, int *pp2, double *t, double *y, double 
   *w, double *alf, S_fp ada, int *isel,
   double *a, double *b, double *u, double *r__, 
   double *rnorm, int *gc, int *thread, int *static_store);
    doublereal dta, last_prjres__;
    integer inc, nlp1;
    doublereal acum;
    integer iter, ksub;
    logical skip;
    integer jsub, isub;
    doublereal rnew;
    integer lnls1;
    extern /* Subroutine */ int updatestatus_(integer *, integer *, integer *,
        doublereal *, integer *);
    integer modit;
    extern doublereal xnorm_(integer *, doublereal *);
    extern /* Subroutine */ int orfac1_(integer *, integer *, integer *, 
       integer *, integer *, integer *, doublereal *, doublereal *, 
       integer *), orfac2_(integer *, integer *, doublereal *, 
       doublereal *), bacsub_(integer *, integer *, doublereal *, 
       doublereal *);
    doublereal r_best__;
    integer iterin;
    doublereal gnstep;
    extern /* Subroutine */ int varerr_(integer *, integer *, integer *);
    doublereal prjres;
    extern /* Subroutine */ int postpr_(integer *, integer *, integer *, 
       integer *, integer *, integer *, integer *, integer *, integer *, 
       integer *, doublereal *, doublereal *, integer *, doublereal *, 
       doublereal *, doublereal *, doublereal *, doublereal *, 
       doublereal *, integer *);
    real prj_tol__;

/*     ============================================================== */

/*        GIVEN S SETS OF N OBSERVATIONS EACH, Y(1,1), ..., Y(N,S), OF A */
/*        DEPENDENT VARIABLE Y, WHERE Y(I,J) CORRESPONDS TO THE IV */
/*        INDEPENDENT VARIABLE(S) T(I,1), T(I,2), ..., T(I,IV), VARP2 */
/*        ATTEMPTS TO COMPUTE A WEIGHTED LEAST SQUARES FIT TO A FUNCTION */
/*        ETA (THE 'MODEL') WHICH IS A LINEAR COMBINATION */

/*                             L */
/*        ETA (ALF,BETA; T) = SUM BETA   * PHI (ALF;T) + PHI   (ALF;T) */
/*           K                J=1     J,K     J             L+1 */

/*        OF NONLINEAR FUNCTIONS PHI(J) (E.G., A SUM OF EXPONENTIALS AND/ */
/*        OR GAUSSIANS).  THAT IS, DETERMINE THE LINEAR PARAMETERS */
/*        BETA(J,K) FOR J=1,2,...,L, K=1,2,...,S, AND THE VECTOR OF */
/*        NONLINEAR PARAMETERS ALF BY MINIMIZING THE FROBENIUS NORM OF */
/*        THE MATRIX OF RESIDUALS: */

/*                         2     S    N                             2 */
/*           NORM(RESIDUAL)  =  SUM  SUM W *(Y   -ETA (ALF,BETA;T )) . */
/*                              K=1  I=1  I   I,K    K           I */

/*        THE (L+1)-ST TERM IS OPTIONAL, AND IS USED WHEN IT IS DESIRED */
/*        TO FIX ONE OR MORE OF THE BETA'S (RATHER THAN LET THEM BE */
/*        DETERMINED).  VARP2 REQUIRES FIRST DERIVATIVES OF THE PHI'S. */

/*                                NOTES: */

/*        A) FOR S=1, THE PROBLEM IS A NONLINEAR LEAST SQUARES PROBLEM */
/*        OF THE TYPE HANDLED IN REFERENCE 1.  THE CASE WITH S>1 SOLVES */
/*        A SIMILAR PROBLEM WHITH MULTIPLE RIGHT HAND SIDES, EACH ALLOWED */
/*        TO HAVE DIFFERENT LINEAR COEFFICIENTS, BUT CONSTRAINED TO HAVE */
/*        THE SAME NONLINEAR PARAMETERS. SEE REFERENCE 8. */

/*        B)  THE ORIGINAL PROGRAM VARPRO (OF WHICH THIS IS A MODIFI- */
/*        CATION) IS AVAILABLE FOR THE SPECIAL CASE S=1.  FOR THAT CASE */
/*        VARPRO IS EASIER TO USE AND HAS THE ADDED ADVANTAGE THAT IT */
/*        RETURNS THE COVARIANCE MATRIX OF THE PARAMETERS AND THE ESTI- */
/*        MATED VARIANCE OF THE OBSERVATIONS. */

/*        C) AN ETA OF THE ABOVE FORM IS CALLED 'SEPARABLE'.  THE */
/*        CASE OF A NONSEPARABLE ETA CAN BE HANDLED BY SETTING L = 0 */
/*        AND USING PHI(L+1). */

/*        D) VARP2 MAY ALSO BE USED TO SOLVE LINEAR LEAST SQUARES */
/*        PROBLEMS (IN THAT CASE NO ITERATIONS ARE PERFORMED).  SET */
/*        NL = 0. */

/*        E)  THE MAIN ADVANTAGE OF VARP2 OVER OTHER LEAST SQUARES */
/*        PROGRAMS IS THAT NO INITIAL GUESSES ARE NEEDED FOR THE LINEAR */
/*        PARAMETERS.  NOT ONLY DOES THIS MAKE IT EASIER TO USE, BUT IT */
/*        OFTEN LEADS TO FASTER CONVERGENCE. */


/*     DESCRIPTION OF PARAMETERS */

/*        S       NUMBER OF RIGHT HAND SIDES. */
/*        L       NUMBER OF LINEAR PARAMETERS BETA FOR EACH RIGHT */
/*                SIDE (MUST BE .GE. 0). */
/*        LMAX    THE DECLARED ROW DIMENSION OF THE MATRIX BETA. */
/*        NL      NUMBER OF NONLINEAR PARAMETERS ALF (MUST BE .GE. 0). */
/*        N       NUMBER OF OBSERVATIONS FOR EACH RIGHT HAND SIDE. */
/*                S*N MUST BE GREATER THAN S*L + NL */
/*                (I.E., THE NUMBER OF OBSERVATIONS MUST EXCEED THE */
/*                NUMBER OF PARAMETERS). */
/*        IV      NUMBER OF INDEPENDENT VARIABLES T. */
/*        T       REAL N BY IV MATRIX OF INDEPENDENT VARIABLES.  T(I, J) */
/*                CONTAINS THE VALUE OF THE I-TH OBSERVATION OF THE J-TH */
/*                INDEPENDENT VARIABLE. */
/*        Y       N BY S MATRIX OF OBSERVATIONS CORRESPONDING TO THE S */
/*                RIGHT HAND SIDES, EACH OF WHICH HAS N VALUES, ONE */
/*                FOR EACH ROW OF T. */
/*        W       N-VECTOR OF NONNEGATIVE WEIGHTS.  W(I) IS THE WEIGHT */
/*                OF THE I'TH OBSERVATION FOR ALL OF THE S RIGHT HAND */
/*                SIDES.  THERE IS CURRENTLY NO PROVISION FOR GIVING */
/*                DIFFERENT WEIGHTS FOR EACH RHS.  W SHOULD BE SET TO */
/*                1'S IF WEIGHTS ARE NOT DESIRED.  IF VARIANCES OF THE */
/*                INDIVIDUAL OBSERVATIONS ARE KNOWN, W(I) SHOULD BE SET */
/*                TO 1./VARIANCE(I). */
/*        INC     NL X (L+1) INTEGER INCIDENCE MATRIX.  INC(K, J) = 1 IF */
/*                NON-LINEAR PARAMETER ALF(K) APPEARS IN THE J-TH */
/*                FUNCTION PHI(J).  (THE PROGRAM SETS ALL OTHER INC(K, J) */
/*                TO ZERO.)  IF PHI(L+1) IS INCLUDED IN THE MODEL, */
/*                THE APPROPRIATE ELEMENTS OF THE (L+1)-ST COLUMN SHOULD */
/*                BE SET TO 1'S.  INC IS NOT NEEDED WHEN L = 0 OR NL = 0. */
/*                CAUTION:  THE DECLARED ROW DIMENSION OF INC (IN ADA) */
/*                MUST CURRENTLY BE SET TO 12.  SEE 'RESTRICTIONS' BELOW. */
/*        NMAX    THE DECLARED ROW DIMENSION OF THE MATRICES Y AND T. */
/*                IT MUST BE AT LEAST N. */
/*        NDIM    THE DECLARED ROW DIMENSION OF THE MATRIX A.  IT MUST */
/*                BE AT LEAST MAX(N, 2*NL+3, S*N - (S-1)*L). */
/*        LPPS1    L+P+S+1, WHERE P IS THE NUMBER OF ONES IN THE MATRIX */
/*                INC. THE DECLARED COLUMN DIMENSION OF A MUST BE AT */
/*                LEAST LPPS1.  (IF L = 0, SET LPPS1 = NL+S+1. IF NL = */
/*                0, SET LPPS1 = L+S+1.) */
/*        A       REAL MATRIX OF SIZE NDIM BY LPPS1. */
/*        IPRINT  INPUT INTEGER CONTROLLING PRINTED OUTPUT.  IF IPRINT IS */
/*                POSITIVE, THE NONLINEAR PARAMETERS, THE NORM OF THE */
/*                RESIDUAL, AND THE MARQUARDT PARAMETER WILL BE OUTPUT */
/*                EVERY IPRINT-TH ITERATION (AND INITIALLY, AND AT THE */
/*                FINAL ITERATION).  THE LINEAR PARAMETERS WILL BE */
/*                PRINTED AT THE FINAL ITERATION.  ANY ERROR MESSAGES */
/*                WILL ALSO BE PRINTED.  (IPRINT = 1 IS RECOMMENDED AT */
/*                FIRST.) IF IPRINT = 0, ONLY THE FINAL QUANTITIES WILL */
/*                BE PRINTED, AS WELL AS ANY ERROR MESSAGES.  IF IPRINT = */
/*                -1, NO PRINTING WILL BE DONE.  THE USER IS THEN */
/*                RESPONSIBLE FOR CHECKING THE PARAMETER IERR FOR ERRORS. */
/*        ALF     NL-VECTOR OF ESTIMATES OF NONLINEAR PARAMETERS */
/*                (INPUT).  ON OUTPUT IT WILL CONTAIN OPTIMAL VALUES OF */
/*                THE NONLINEAR PARAMETERS. */
/*        BETA    L BY S MATRIX OF LINEAR PARAMETERS WITH DECLARED */
/*                ROW DIMENSION LMAX. */
/*        IERR    INTEGER ERROR FLAG (OUTPUT): */
/*                .GT. 0 - SUCCESSFUL CONVERGENCE, IERR IS THE NUMBER OF */
/*                    ITERATIONS TAKEN. */
/*                -1  TERMINATED FOR TOO MANY ITERATIONS. */
/*                -2  TERMINATED FOR ILL-CONDITIONING (MARQUARDT */
/*                    PARAMETER TOO LARGE.)  ALSO SEE IERR = -8 BELOW. */
/*                -4  INPUT ERROR IN PARAMETER N, L, NL, LPPS1, OR NMAX. */
/*                -5  INC MATRIX IMPROPERLY SPECIFIED, OR P DISAGREES */
/*                    WITH LPPS1. */
/*                -6  A WEIGHT WAS NEGATIVE. */
/*                -7  'CONSTANT' COLUMN WAS COMPUTED MORE THAN ONCE. */
/*                -8  CATASTROPHIC FAILURE - A COLUMN OF THE A MATRIX HAS */
/*                    BECOME ZERO.  SEE 'CONVERGENCE FAILURES' BELOW. */


/*     SUBROUTINES REQUIRED */

/*           NINE SUBROUTINES, DPA, ORFAC1, ORFAC2, BACSUB, POSTPR, COV, */
/*        XNORM, INIT, AND VARERR ARE PROVIDED.  IN ADDITION, THE USER */
/*        MUST PROVIDE A SUBROUTINE (CORRESPONDING TO THE ARGUMENT ADA) */
/*        WHICH, GIVEN ALF, WILL EVALUATE THE FUNCTIONS PHI(J) AND THEIR */
/*        PARTIAL DERIVATIVES D PHI(J)/D ALF(K), AT THE SAMPLE POINTS */
/*        T(I).  THIS ROUTINE MUST BE DECLARED 'EXTERNAL' IN THE CALLING */
/*        PROGRAM.  ITS CALLING SEQUENCE IS */

/*        SUBROUTINE ADA (S, L+1, NL, N, NMAX, NDIM, LPPS1, IV, A, */
/*        INC, T, ALF, ISEL) */

/*           THE USER SHOULD MODIFY THE EXAMPLE SUBROUTINE 'ADA' (GIVEN */
/*        ELSEWHERE) FOR HIS OWN FUNCTIONS. */

/*           THE VECTOR SAMPLED FUNCTIONS PHI(J) SHOULD BE STORED IN THE */
/*        FIRST N ROWS AND FIRST L+1 COLUMNS OF THE MATRIX A, I.E., */
/*        A(I, J) SHOULD CONTAIN PHI(J, ALF; T(I,1), T(I,2), ..., */
/*        T(I,IV)), I = 1, ..., N; J = 1, ..., L (OR L+1).  THE (L+1)-ST */
/*        COLUMN OF A CONTAINS PHI(L+1) IF PHI(L+1) IS IN THE MODEL, */
/*        OTHERWISE IT IS RESERVED FOR WORKSPACE.  IF S>1, COLUMNS */
/*        L+2 THROUGH L+S ARE ALSO RESERVED.  THE 'CONSTANT' FUNCTIONS */
/*        (THESE ARE FUNCTIONS PHI(J) WHICH DO NOT DEPEND UPON ANY */
/*        NONLINEAR PARAMETERS ALF, E.G., T(I)**J) (IF ANY) MUST APPEAR */
/*        FIRST, STARTING IN COLUMN 1.  THE COLUMN N-VECTORS OF NONZERO */
/*        PARTIAL DERIVATIVES D PHI(J) / D ALF(K) SHOULD BE STORED */
/*        SEQUENTIALLY IN THE MATRIX A IN COLUMNS L+S+1 THROUGH L+S+P. */
/*        THE ORDER IS */

/*          D PHI(1)  D PHI(2)        D PHI(L)  D PHI(L+1)  D PHI(1) */
/*          --------, --------, ...,  --------, ----------, --------, */
/*          D ALF(1)  D ALF(1)        D ALF(1)   D ALF(1)   D ALF(2) */

/*          D PHI(2)       D PHI(L+1)       D PHI(1)        D PHI(L+1) */
/*          --------, ..., ----------, ..., ---------, ..., ----------, */
/*          D ALF(2)        D ALF(2)        D ALF(NL)       D ALF(NL) */

/*        OMITTING COLUMNS OF DERIVATIVES WHICH ARE ZERO, AND OMITTING */
/*        PHI(L+1) COLUMNS IF PHI(L+1) IS NOT IN THE MODEL.  NOTE THAT */
/*        THE LINEAR PARAMETERS BETA ARE NOT USED IN THE MATRIX A. */
/*        COLUMN L+P+S+1 IS RESERVED FOR WORKSPACE. */

/*        THE CODING OF ADA SHOULD BE ARRANGED SO THAT: */

/*        ISEL = 1  (WHICH OCCURS THE FIRST TIME ADA IS CALLED) MEANS: */
/*                  A.  FILL IN THE INCIDENCE MATRIX INC */
/*                  B.  STORE ANY CONSTANT PHI'S IN A. */
/*                  C.  COMPUTE NONCONSTANT PHI'S AND PARTIAL DERIVA- */
/*                      TIVES. */
/*             = 2  MEANS COMPUTE ONLY THE NONCONSTANT FUNCTIONS PHI */
/*             = 3  MEANS COMPUTE ONLY THE DERIVATIVES */

/*        (WHEN THE PROBLEM IS LINEAR (NL = 0) ONLY ISEL = 1 IS USED, AND */
/*        DERIVATIVES ARE NOT NEEDED.) */

/*     RESTRICTIONS */

/*           THE SUBROUTINES DPA, INIT (AND ADA) CONTAIN THE LOCALLY */
/*        DIMENSIONED MATRIX INC, WHOSE DIMENSIONS ARE CURRENTLY SET FOR */
/*        MAXIMA OF L+1 = 8, NL = 12.  THEY MUST BE CHANGED FOR LARGER */
/*        PROBLEMS.  DATA PLACED IN ARRAY A IS OVERWRITTEN ('DESTROYED'). */
/*        DATA PLACED IN ARRAYS T, Y AND INC IS LEFT INTACT.  THE PROGRAM */
/*        RUNS IN WATFIV, EXCEPT WHEN L = 0 OR NL = 0. */

/*           IT IS ASSUMED THAT THE MATRIX PHI(J, ALF; T(I)) HAS FULL */
/*        COLUMN RANK.  THIS MEANS THAT THE FIRST L COLUMNS OF THE MATRIX */
/*        A MUST BE LINEARLY INDEPENDENT. */

/*           OPTIONAL NOTE:  AS WILL BE NOTED FROM THE SAMPLE SUBPROGRAM */
/*        ADA, THE DERIVATIVES D PHI(J)/D ALF(K) (ISEL = 3) MUST BE */
/*        COMPUTED INDEPENDENTLY OF THE FUNCTIONS PHI(J) (ISEL = 2), */
/*        SINCE THE FUNCTION VALUES ARE OVERWRITTEN AFTER ADA IS CALLED */
/*        WITH ISEL = 2.  THIS IS DONE TO MINIMIZE STORAGE, AT THE POS- */
/*        SIBLE EXPENSE OF SOME RECOMPUTATION (SINCE THE FUNCTIONS AND */
/*        DERIVATIVES FREQUENTLY HAVE SOME COMMON SUBEXPRESSIONS).  TO */
/*        REDUCE THE AMOUNT OF COMPUTATION AT THE EXPENSE OF SOME */
/*        STORAGE, CREATE A MATRIX B OF DIMENSION NMAX BY L+1 IN ADA, AND */
/*        AFTER THE COMPUTATION OF THE PHI'S (ISEL = 2), COPY THE VALUES */
/*        INTO B.  THESE VALUES CAN THEN BE USED TO CALCULATE THE DERIV- */
/*        ATIVES (ISEL = 3).  (THIS MAKES USE OF THE FACT THAT WHEN A */
/*        CALL TO ADA WITH ISEL = 3 FOLLOWS A CALL WITH ISEL = 2, THE */
/*        ALFS ARE THE SAME.) */

/*           TO CONVERT TO OTHER MACHINES, CHANGE THE OUTPUT UNIT IN THE */
/*        DATA STATEMENTS IN VARP2, DPA, POSTPR, AND VARERR.  THE */
/*        PROGRAM HAS BEEN CHECKED FOR PORTABILITY BY THE BELL LABS PFORT */
/*        VERIFIER.  FOR MACHINES WITHOUT DOUBLE PRECISION HARDWARE, IT */
/*        MAY BE DESIRABLE TO CONVERT TO SINGLE PRECISION.  THIS CAN BE */
/*        DONE BY CHANGING (A) THE DECLARATIONS 'DOUBLE PRECISION' TO */
/*        'REAL', (B) THE PATTERN '.D' TO '.E' IN THE 'DATA' STATEMENT IN */
/*        VARP2, (C) DSIGN, DSQRT AND DABS TO SIGN, SQRT AND ABS, */
/*        RESPECTIVELY, AND (D) DEXP TO EXP IN THE SAMPLE PROGRAMS ONLY. */

/*     CONVERGENCE FAILURES */

/*           IF CONVERGENCE FAILURES OCCUR, FIRST CHECK FOR INCORRECT */
/*        CODING OF THE SUBROUTINE ADA.  CHECK ESPECIALLY THE ACTION OF */
/*        ISEL, AND THE COMPUTATION OF THE PARTIAL DERIVATIVES.  IF THESE */
/*        ARE CORRECT, TRY SEVERAL STARTING GUESSES FOR ALF.  IF ADA */
/*        IS CODED CORRECTLY, AND IF ERROR RETURNS IERR = -2 OR -8 */
/*        PERSISTENTLY OCCUR, THIS IS A SIGN OF ILL-CONDITIONING, WHICH */
/*        MAY BE CAUSED BY SEVERAL THINGS.  ONE IS POOR SCALING OF THE */
/*        PARAMETERS; ANOTHER IS AN UNFORTUNATE INITIAL GUESS FOR THE */
/*        PARAMETERS, STILL ANOTHER IS A POOR CHOICE OF THE MODEL. */

/*     ALGORITHM */

/*           THE RESIDUAL R IS MODIFIED TO INCORPORATE, FOR ANY FIXED */
/*        ALF, THE OPTIMAL LINEAR PARAMETERS FOR THAT ALF.  IT IS THEN */
/*        POSSIBLE TO MINIMIZE ONLY ON THE NONLINEAR PARAMETERS.  AFTER */
/*        THE OPTIMAL VALUES OF THE NONLINEAR PARAMETERS HAVE BEEN DETER- */
/*        MINED, THE LINEAR PARAMETERS CAN BE RECOVERED BY LINEAR LEAST */
/*        SQUARES TECHNIQUES (SEE REF. 1). */

/*           THE MINIMIZATION IS BY A MODIFICATION OF OSBORNE'S (REF. 3) */
/*        MODIFICATION OF THE LEVENBERG-MARQUARDT ALGORITHM.  INSTEAD OFcv */
/*        SOLVING THE NORMAL EQUATIONS WITH MATRIX */

/*                 T      2 */
/*               (J J + NU  * D),      WHERE  J = D(ETA)/D(ALF), */

/*        STABLE ORTHOGONAL (HOUSEHOLDER) REFLECTIONS ARE USED ON A */
/*        MODIFICATION OF THE MATRIX */
/*                                   (   J  ) */
/*                                   (------) , */
/*                                   ( NU*D ) */

/*        WHERE D IS A DIAGONAL MATRIX CONSISTING OF THE LENGTHS OF THE */
/*        COLUMNS OF J.  THIS MARQUARDT STABILIZATION ALLOWS THE ROUTINE */
/*        TO RECOVER FROM SOME RANK DEFICIENCIES IN THE JACOBIAN. */
/*        OSBORNE'S EMPIRICAL STRATEGY FOR CHOOSING THE MARQUARDT PARAM- */
/*        ETER HAS PROVEN REASONABLY SUCCESSFUL IN PRACTICE.  (GAUSS- */
/*        NEWTON WITH STEP CONTROL CAN BE OBTAINED BY MAKING THE CHANGE */
/*        INDICATED BEFORE THE INSTRUCTION LABELED 5).  A DESCRIPTION CAN */
/*        BE FOUND IN REF. (3), AND A FLOW CHART IN (2), P. 22. */

/*        FOR REFERENCE, SEE */

/*        1.  GENE H. GOLUB AND V. PEREYRA, 'THE DIFFERENTIATION OF */
/*            PSEUDO-INVERSES AND NONLINEAR LEAST SQUARES PROBLEMS WHOSE */
/*            VARIABLES SEPARATE,' SIAM J. NUMER. ANAL. 10, 413-432 */
/*            (1973). */
/*        2.  ------, SAME TITLE, STANFORD C.S. REPORT 72-261, FEB. 1972. */
/*        3.  OSBORNE, MICHAEL R., 'SOME ASPECTS OF NON-LINEAR LEAST */
/*            SQUARES CALCULATIONS,' IN LOOTSMA, ED., 'NUMERICAL METHODS */
/*            FOR NON-LINEAR OPTIMIZATION,' ACADEMIC PRESS, LONDON, 1972. */
/*        4.  KROGH, FRED, 'EFFICIENT IMPLEMENTATION OF A VARIABLE PRO- */
/*            JECTION ALGORITHM FOR NONLINEAR LEAST SQUARES PROBLEMS,' */
/*            COMM. ACM 17, PP. 167-169 (MARCH, 1974). */
/*        5.  KAUFMAN, LINDA, 'A VARIABLE PROJECTION METHOD FOR SOLVING */
/*            SEPARABLE NONLINEAR LEAST SQUARES PROBLEMS', B.I.T. 15, */
/*            49-57 (1975). */
/*        6.  DRAPER, N., AND SMITH, H., APPLIED REGRESSION ANALYSIS, */
/*            WILEY, N.Y., 1966 (FOR STATISTICAL INFORMATION ONLY). */
/*        7.  C. LAWSON AND R. HANSON, SOLVING LEAST SQUARES PROBLEMS, */
/*            PRENTICE-HALL, ENGLEWOOD CLIFFS, N. J., 1974. */
/*        8.  GOLUB, G. AND LEVEQUE, R., EXTENSIONS AND USES OF THE */
/*            VARIABLE PROJECTION ALGORITHM FOR SOLVING NONLINEAR LEAST */
/*            SQUARES PROBLEMS,  PROC. 1979 ARMY NUM. ANAL. AND COMPUTERS */
/*            CONF., ARO REPORT 79-3, PP. 1-12. */

/*                      VICTOR PEREYRA */
/*                      ESCUELA DE COMPUTACION */
/*                      FACULTAD DE CIENCIAS */
/*                      UNIVERSIDAD CENTRAL DE VENEZUELA */
/*                      CARACAS, VENEZUELA */

/*                      JOHN BOLSTAD */
/*                      COMPUTER SCIENCE DEPT., SERRA HOUSE */
/*                      STANFORD UNIVERSITY */
/*                      JANUARY, 1977 */

/*                      RANDY LEVEQUE */
/*                      COMPUTER SCIENCE DEPT., SERRA HOUSE */
/*                      STANFORD UNIVERSITY */
/*                      DECEMBER, 1978 */

/*     .................................................................. */

    /* Parameter adjustments */
    beta_dim1 = *l;
    beta_offset = 1 + beta_dim1;
    beta -= beta_offset;
    --alfbest;
    --alf;
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

/*           THE FOLLOWING TWO PARAMETERS ARE USED IN THE CONVERGENCE */
/*           TEST:  EPS1 IS AN ABSOLUTE AND RELATIVE TOLERANCE FOR THE */
/*           NORM OF THE PROJECTION OF THE RESIDUAL ONTO THE RANGE OF THE */
/*           JACOBIAN OF THE VARIABLE PROJECTION FUNCTIONAL. */
/*           ITMAX IS THE MAXIMUM NUMBER OF FUNCTION AND DERIVATIVE */
/*           EVALUATIONS ALLOWED.  CAUTION:  EPS1 MUST NOT BE */
/*           SET SMALLER THAN 10 TIMES THE UNIT ROUND-OFF OF THE MACHINE. */
/* ----------------------------------------------------------------- */
    eps1 = 1e-6;
    prj_tol__ = 1e-2;
    r_best__ = 1e10;
    prjres = 0.;
    *ierr = 1;
    iter = 0;
    lp1 = *l + 1;
    b1 = *l + *s + 1;
    lnls1 = *l + *nl + *s + 1;
    nlp1 = *nl + 1;
    skip = FALSE_;
    modit = *iprint;
    rnew = 0.;
    if (*iprint <= 0) {
   modit = *itmax + 2;
    }
    nu = (float)0.;
/*              IF GAUSS-NEWTON IS DESIRED REMOVE THE NEXT STATEMENT. */
    if (*gn == 1) {
   goto L5;
    }
    nu = (float)1.;

/*              BEGIN OUTER ITERATION LOOP TO UPDATE ALF. */
/*              CALCULATE THE NORM OF THE RESIDUAL AND THE DERIVATIVE OF */
/*              THE MODIFIED RESIDUAL THE FIRST TIME, BUT ONLY THE */
/*              DERIVATIVE IN SUBSEQUENT ITERATIONS. */

L5:
    dpa_(s, l, nl, n, nmax, ndim, lpps1, lps, pp2, &t[t_offset], &y[
       y_offset], &w[1], &alf[1], (S_fp)ada, ierr, iprint, &a[a_offset], 
       &b[b_offset], &beta[beta_offset], &a[lp1 * a_dim1 + 1], r__, gc, 
       thread, sstore);
    gnstep = (float)1.;
    iterin = 0;
    if (iter > 0) {
   goto L10;
    }
    if (*nl == 0) {
   goto L90;
    }
    if (*ierr != 1) {
   goto L99;
    }

    if (*iprint <= 0) {
   goto L10;
    }
/*        WRITE (OUTPUT, 207) ITERIN, R */
/*        WRITE (OUTPUT, 200) NU */
/*                              BEGIN TWO-STAGE ORTHOGONAL FACTORIZATION */
L10:
    last_prjres__ = prjres;
    orfac1_(s, &nlp1, ndim, n, l, iprint, &b[b_offset], &prjres, ierr);
    if (*ierr < 0) {
   goto L99;
    }
    *ierr = 2;
    if (nu == (float)0.) {
   goto L30;
    }

/*              BEGIN INNER ITERATION LOOP FOR GENERATING NEW ALF AND */
/*              TESTING IT FOR ACCEPTANCE. */

L25:
    orfac2_(&nlp1, ndim, &nu, &b[b_offset]);

/*              SOLVE A NL X NL UPPER TRIANGULAR SYSTEM FOR DELTA-ALF. */
/*              THE TRANSFORMED RESIDUAL (IN COL. LNLS1 OF A) IS OVER- */
/*              WRITTEN BY THE RESULT DELTA-ALF. */

L30:
    bacsub_(ndim, nl, &b[b_offset], &b[(*nl + 1) * b_dim1 + 1]);
    i__1 = *nl;
    for (k = 1; k <= i__1; ++k) {
/* L35: */
   b[k + b_dim1] = alf[k] + b[k + (*nl + 1) * b_dim1];
    }
/*           NEW ALF(K) = ALF(K) + DELTA ALF(K) */

/*              STEP TO THE NEW POINT NEW ALF, AND COMPUTE THE NEW */
/*              NORM OF RESIDUAL.  NEW ALF IS STORED IN COLUMN B1 OF A. */

L40:
    dpa_(s, l, nl, n, nmax, ndim, lpps1, lps, pp2, &t[t_offset], &y[
       y_offset], &w[1], &b[b_offset], (S_fp)ada, ierr, iprint, &a[
       a_offset], &b[b_offset], &beta[beta_offset], &a[lp1 * a_dim1 + 1],
        &rnew, gc, thread, sstore);
    if (*ierr != 2) {
   goto L99;
    }
    ++iter;
    ++iterin;
/*        SKIP = MOD(ITER, MODIT) .NE. 0 */
/*        IF (SKIP) GO TO 45 */
/*           WRITE (OUTPUT, 203) ITER */
/*           WRITE (OUTPUT, 216) (A(K, B1), K = 1, NL) */
/*           WRITE (OUTPUT, 207) ITERIN, RNEW */
    r__1 = (real) (*s);
    d__1 = rnew / sqrt(r__1);
    updatestatus_(gc, thread, &iter, &d__1, &terminate);
    if (terminate == 0) {
   goto L45;
    }
    *ierr = -9;
    varerr_(iprint, ierr, &c__1);
    goto L95;

L45:
    if (iter < *itmax) {
   goto L50;
    }
    *ierr = -1;
    varerr_(iprint, ierr, &c__1);
    goto L95;
L50:
    if (rnew - *r__ < eps1 * (*r__ + 1.)) {
   goto L75;
    }

/*              RETRACT THE STEP JUST TAKEN */

    if (nu != (float)0.) {
   goto L60;
    }
/*                                             GAUSS-NEWTON OPTION ONLY */
    gnstep *= (float).5;
    if (gnstep < eps1) {
   goto L95;
    }
    i__1 = *nl;
    for (k = 1; k <= i__1; ++k) {
/* L55: */
   b[k + b_dim1] = alf[k] + gnstep * b[k + (*nl + 1) * b_dim1];
    }
    goto L40;
/*                                        ENLARGE THE MARQUARDT PARAMETER */
L60:
    nu *= (float)1.5;
/*           IF (.NOT. SKIP) WRITE (OUTPUT, 206) NU */
    if (nu <= (float)100.) {
   goto L65;
    }
    *ierr = -2;
    varerr_(iprint, ierr, &c__1);
    goto L95;
/*                                        RETRIEVE UPPER TRIANGULAR FORM */
/*                                        AND RESIDUAL OF FIRST STAGE. */
L65:
    i__1 = *nl;
    for (k = 1; k <= i__1; ++k) {
   ksub = *lps + k;
   i__2 = nlp1;
   for (j = k; j <= i__2; ++j) {
       jsub = *lps + j;
       isub = nlp1 + j;
/* L70: */
       b[k + j * b_dim1] = b[isub + k * b_dim1];
   }
    }
    goto L25;
/*                                        END OF INNER ITERATION LOOP */
/*           ACCEPT THE STEP JUST TAKEN */

L75:
    *r__ = rnew;
    i__2 = *nl;
    for (k = 1; k <= i__2; ++k) {
/* L80: */
   alf[k] = b[k + b_dim1];
    }

    if (rnew >= r_best__) {
   goto L82;
    }
    r_best__ = rnew;
    i__2 = *nl;
    for (k = 1; k <= i__2; ++k) {
/* L81: */
   alfbest[k] = alf[k];
    }

/*                                        CALC. NORM(DELTA ALF)/NORM(ALF) */
L82:
    acum = gnstep * xnorm_(nl, &b[(*nl + 1) * b_dim1 + 1]) / xnorm_(nl, &alf[
       1]);

/*           IF ITERIN IS GREATER THAN 1, A STEP WAS RETRACTED DURING */
/*           THIS OUTER ITERATION. */

    if (iterin == 1) {
   nu *= (float).5;
    }
    if (skip) {
   goto L85;
    }
/*        WRITE (OUTPUT, 200) NU */
/*        WRITE (OUTPUT, 208) ACUM */
L85:
    *ierr = 3;
    dta = (last_prjres__ - prjres) / last_prjres__;
/*      IF (PRJRES .GT. EPS1*(R + 1.D0) .AND. DTA .GT. PRJ_TOL) GO TO 5 */
    if (prjres > eps1 * (*r__ + 1.) && (dta > prj_tol__ || last_prjres__ == 0)) { 
   goto L5;
    }
/*           END OF OUTER ITERATION LOOP */

/*           CALCULATE FINAL QUANTITIES -- LINEAR PARAMETERS, RESIDUALS, */

L90:
    *ierr = iter;
L95:
    if (*nl > 0) {
   dpa_(s, l, nl, n, nmax, ndim, lpps1, lps, pp2, &t[t_offset],
       &y[y_offset], &w[1], &alf[1], (S_fp)ada, &c__3, iprint, &a[
      a_offset], &b[b_offset], &beta[beta_offset], &a[lp1 * a_dim1 
      + 1], r__, gc, thread, sstore);
    }
    postpr_(s, l, lmax, nl, n, nmax, ndim, &lnls1, lps, pp2, &eps1, r__, 
       iprint, &alf[1], &w[1], &a[a_offset], &b[b_offset], &a[lp1 * 
       a_dim1 + 1], &beta[beta_offset], ierr);

    c__2 = 1;
    (*ada)(s, &lp1, nl, n, nmax, ndim, lpps1, pp2, &a[a_offset], &b[
       b_offset], 0, &inc, &t[t_offset], &alf[1], &c__2, gc, thread);
L99:
    return 0;

/* L200: */
/* L203: */
/* L206: */
/* L207: */
/* L208: */
/* L216: */
} /* varp2_ */


/*     ============================================================== */
/* Subroutine */ int orfac1_(integer *s, integer *nlp1, integer *ndim, 
   integer *n, integer *l, integer *iprint, doublereal *b, doublereal *
   prjres, integer *ierr)
{
   /* System generated locals */
   integer b_dim1, b_offset, i__2;
   doublereal d__1;

   /* Builtin functions */
   double d_sign(doublereal *, doublereal *);

   /* Local variables */
   integer i__, j, k;
   doublereal u;
   integer nl, kp1, lp1, nl23, lpk;
   doublereal beta, acum;
   integer jsub, nsls1;
   doublereal alpha;
   extern doublereal xnorm_(integer *, doublereal *);
   extern /* Subroutine */ int varerr_(integer *, integer *, integer *);

/*     ============================================================== */

/*            STAGE 1:  HOUSEHOLDER REDUCTION OF */

/*                   (    .    )      ( DR'. R3 )    NL */
/*                   ( DR . R2 )  TO  (----. -- ), */
/*                   (    .    )      (  0 . R4 )  N-L-NL */

/*                     NL    1          NL   1 */

/*         WHERE DR = -D(Q2)*Y IS THE DERIVATIVE OF THE MODIFIED RESIDUAL */
/*         PRODUCED BY DPA, R2 IS THE TRANSFORMED RESIDUAL FROM DPA, AND */
/*         DR' IS IN UPPER TRIANGULAR FORM (AS IN REF. (2), P. 18). */
/*         DR IS STORED IN ROWS L+1 TO N*S-L*(S-1) AND COLUMNS L+S+1 TO */
/*         L+S+NL OF THE MATRIX A (I.E., COLUMNS 1 TO NL OF THE MATRIX B). */
/*         R2 IS STORED IN COLUMN L+NL+S+1 OF THE MATRIX A (COLUMN NL + 1 */
/*         OF B).  FOR K = 1, 2, ..., NL, FIND REFLECTION I - U * U' / */
/*         BETA WHICH ZEROES B(I, K), I = L+K+1, ..., N*S - L*(S-1). */

/*     .................................................................. */


   /* Parameter adjustments */
   b_dim1 = *ndim;
   b_offset = 1 + b_dim1;
   b -= b_offset;
   /* Function Body */
   nl = *nlp1 - 1;
   nsls1 = *n * *s - *l * (*s - 1);
   nl23 = (nl << 1) + 3;
   lp1 = *l + 1;

   for (k = 1; k <= nl; ++k) 
   {
      lpk = *l + k;
      i__2 = nsls1 + 1 - lpk;
      d__1 = xnorm_(&i__2, &b[lpk + k * b_dim1]);
      alpha = d_sign(&d__1, &b[lpk + k * b_dim1]);
      u = b[lpk + k * b_dim1] + alpha;
      b[lpk + k * b_dim1] = u;
      beta = alpha * u;
      
      if (alpha == (float)0.)
      {
         *ierr = -8;
         i__2 = lp1 + k;
         varerr_(iprint, ierr, &i__2);
         goto L99;
      }

      kp1 = k + 1;
      for (j = kp1; j <= *nlp1; ++j) 
      {
         acum = 0.0;
         for (i__ = lpk; i__ <= nsls1; ++i__) 
            acum += b[i__ + k * b_dim1] * b[i__ + j * b_dim1];
         acum /= beta;
         for (i__ = lpk; i__ <= nsls1; ++i__)
            b[i__ + j * b_dim1] -= b[i__ + k * b_dim1] * acum;
      }
      b[lpk + k * b_dim1] = -alpha;
   }

    *prjres = xnorm_(&nl, &b[lp1 + *nlp1 * b_dim1]);

/*           SAVE UPPER TRIANGULAR FORM AND TRANSFORMED RESIDUAL, FOR USE */
/*           IN CASE A STEP IS RETRACTED.  ALSO COMPUTE COLUMN LENGTHS. */

   if (*ierr == 4)
      goto L99;

   for (k = 1; k <= nl; ++k) 
   {
      lpk = *l + k;
      for (j = k; j <= *nlp1; ++j) 
      {
         jsub = *nlp1 + j;
         b[k + j * b_dim1] = b[lpk + j * b_dim1];
         b[jsub + k * b_dim1] = b[lpk + j * b_dim1];
      }
      b[nl23 + k * b_dim1] = xnorm_(&k, &b[lp1 + k * b_dim1]);
   }

L99:
    return 0;
} /* orfac1_ */


/*     ============================================================== */
/* Subroutine */ int orfac2_(integer *nlp1, integer *ndim, doublereal *nu, 
   doublereal *b)
{
    /* System generated locals */
    integer b_dim1, b_offset, i__2;
    doublereal d__1;

    /* Builtin functions */
    double d_sign(doublereal *, doublereal *);

    /* Local variables */
    integer i__, j, k;
    doublereal u;
    integer nl, nl2, kp1, nl23;
    doublereal beta, acum;
    integer nlpk;
    doublereal alpha;
    extern doublereal xnorm_(integer *, doublereal *);
    integer nlpkm1;

/*     ============================================================== */

/*        STAGE 2:  SPECIAL HOUSEHOLDER REDUCTION OF */

/*                      NL     ( DR' . R3 )      (DR'' . R5 ) */
/*                             (-----. -- )      (-----. -- ) */
/*                  N-L-NL     (  0  . R4 )  TO  (  0  . R4 ) */
/*                             (-----. -- )      (-----. -- ) */
/*                      NL     (NU*D . 0  )      (  0  . R6 ) */

/*                                NL    1          NL    1 */

/*        WHERE DR', R3, AND R4 ARE AS IN ORFAC1, NU IS THE MARQUARDT */
/*        PARAMETER, D IS A DIAGONAL MATRIX CONSISTING OF THE LENGTHS OF */
/*        THE COLUMNS OF DR', AND DR'' IS IN UPPER TRIANGULAR FORM. */
/*        DETAILS IN (1), PP. 423-424.  NOTE THAT THE (N-L-NL) BAND OF */
/*        ZEROES, AND R4, ARE OMITTED IN STORAGE. */

/*     .................................................................. */


    /* Parameter adjustments */
    b_dim1 = *ndim;
    b_offset = 1 + b_dim1;
    b -= b_offset;

    /* Function Body */
    nl = *nlp1 - 1;
    nl2 = nl << 1;
    nl23 = nl2 + 3;
    for (k = 1; k <= nl; ++k) 
    {
       kp1 = k + 1;
       nlpk = nl + k;
       nlpkm1 = nlpk - 1;
       b[nlpk + k * b_dim1] = *nu * b[nl23 + k * b_dim1];
       b[nl + k * b_dim1] = b[k + k * b_dim1];
       i__2 = k + 1;
       d__1 = xnorm_(&i__2, &b[nl + k * b_dim1]);
       alpha = d_sign(&d__1, &b[k + k * b_dim1]);
       u = b[k + k * b_dim1] + alpha;
       beta = alpha * u;
       b[k + k * b_dim1] = -alpha;
/*                        THE K-TH REFLECTION MODIFIES ONLY ROWS K, */
/*                        NL+1, NL+2, ..., NL+K, AND COLUMNS K TO NL+1. */

       for (j = kp1; j <= *nlp1; ++j) 
       {
          b[nlpk + j * b_dim1] = (float)0.;
          acum = u * b[k + j * b_dim1];
          for (i__ = *nlp1; i__ <= nlpkm1; ++i__)
             acum += b[i__ + k * b_dim1] * b[i__ + j * b_dim1];
          acum /= beta;
          b[k + j * b_dim1] -= u * acum;
          for (i__ = *nlp1; i__ <= nlpk; ++i__)
             b[i__ + j * b_dim1] -= b[i__ + k * b_dim1] * acum;
      }
   }

   return 0;
} /* orfac2_ */


/*     ============================================================== */
/* Subroutine */ int init_(integer *s, integer *l, integer *nl,
    integer *n, integer *nmax, integer *ndim, integer *lpps1, integer *
   lps, integer *pp2, doublereal *t, doublereal *w, 
   const doublereal *alf, S_fp ada, integer *isel, integer *iprint, doublereal 
   *a, doublereal *b, doublereal *kap, integer *inc, integer *ncon, integer *nconp1, 
   logical *philp1, logical *nowate, integer *gc, integer *thread)
{
    /* System generated locals */
    integer a_dim1, a_offset, b_dim1, b_offset, t_dim1, t_offset, i__2;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    integer ncon_buf__, i__, j, k, p, nconp1_buf__, lp1, lnls1, inckj, philp1_buf__;
    extern /* Subroutine */ int varerr_(integer *, integer *, integer *);

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
    if (*l >= 0 && *nl >= 0 && *s * *l + *nl < *s * *n && lnls1 <= *lpps1 && (
       *nl << 1) + 3 <= *ndim && *n <= *nmax && *n <= *ndim &&
        ! (*nl == 0 && *l == 0) && * // && *s * *n - (*s - 1) * *l <= *ndim
       s > 0 && *l <= *lmax) {
   goto L3;
    }
    *isel = -4;
    varerr_(iprint, isel, &c__1);
    goto L99;

/*    1 IF (L .EQ. 0 .OR. NL .EQ. 0) GO TO 3 */
/*         DO 2 J = 1, LP1 */
/*            DO 2 K = 1, NL */
/*    2          INC(K, J) = 0 */

L3:
    (*ada)(s, &lp1, nl, n, nmax, ndim, lpps1, pp2, &a[a_offset], &b[
       b_offset], kap, &inc[13], &t[t_offset], &alf[1], isel, gc, thread);

   for (i__ = 1; i__ <= *n; ++i__)
   {
      if (w[i__] < (float)0.) 
      {
         /*                                                ERROR IN WEIGHTS */
         *isel = -6;
         varerr_(iprint, isel, &i__);
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
            goto L15;
         if (inckj == 1)
            ++p;
      }
   }

/*     IF (IPRINT .GE. 0) WRITE (OUTPUT, 210) NCON */
    if (*l + p + *s + 1 == *lpps1) {
   goto L20;
    }
/*                                              INPUT ERROR IN INC MATRIX */
L15:
    *isel = -5;
    varerr_(iprint, isel, &c__1);
    goto L99;
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
   *lps, integer *pp2, doublereal *eps, doublereal *rnorm, integer *
   iprint, doublereal *alf, doublereal *w, doublereal *a, doublereal *b, 
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
    u_dim1 = *lmax;
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

/*     ============================================================== */
/* Subroutine */ int varerr_(integer *iprint, integer *ierr, integer *k)
{
/*     ============================================================== */

/*        PRINT ERROR MESSAGES */

/*      INTEGER ERRNO, OUTPUT */
/*      DATA OUTPUT /6/ */

/*      IF (IPRINT .LT. 0) GO TO 99 */
/*      ERRNO = IABS(IERR) */
/*     GO TO (1, 2, 99, 4, 5, 6, 7, 8), ERRNO */

/*   1 WRITE (OUTPUT, 101) */
/*     GO TO 99 */
/*   2 WRITE (OUTPUT, 102) */
/*     GO TO 99 */
/*   4 WRITE (OUTPUT, 104) */
/*     GO TO 99 */
/*   5 WRITE (OUTPUT, 105) */
/*     GO TO 99 */
/*   6 WRITE (OUTPUT, 106) K */
/*     GO TO 99 */
/*   7 WRITE (OUTPUT, 107) K */
/*     GO TO 99 */
/*   8 WRITE (OUTPUT, 108) K */

/* L99: */
    return 0;
/* L101: */
/* L102: */
/* L104: */
/* L105: */
/* L106: */
/* L107: */
/* L108: */
} /* varerr_ */

#ifdef __cplusplus
   }
#endif
