C
C     ==============================================================
      SUBROUTINE DPA (S, L, LMAX, NL, N, NMAX, NDIM, LPPS1, LPS, PP2, 
     X IV, T, Y, W, ALF, ADA, ISEL, IPRINT, A, B, U, R, RNORM, GIDX)
C     ==============================================================
C
C        COMPUTE THE NORM OF THE RESIDUAL (IF ISEL = 1 OR 2), OR THE
C        (N-L) X NL X S DERIVATIVE OF THE MODIFIED RESIDUAL (N-L) BY S
C        MATRIX Q2*Y (IF ISEL = 1 OR 3).  HERE Q * PHI = TRI, I.E.,
C
C         L     ( Q1 ) (     .   .        )   (TRI . R1 .  F1  )
C               (----) ( PHI . Y . D(PHI) ) = (--- . -- . ---- )
C         N-L   ( Q2 ) (     .   .        )   ( 0  . R2 .  F2  )
C
C                 N       L    S      P         L     S     P
C
C        WHERE Q IS N X N ORTHOGONAL, AND TRI IS L X L UPPER TRIANGULAR.
C        THE NORM OF THE RESIDUAL = FROBENIUS NORM(R2), AND THE DESIRED
C        DERIVATIVE ACCORDING TO REF. (5), IS
C                                                 -1
C                    D(Q2 * Y) = -Q2 * D(PHI)* TRI  * Q1* Y.
C
C        THE THREE-TENSOR DERIVATIVE IS STORED IN COLUMNS L+S+1 THROUGH
C        L+S+NL AND ROWS L+1 THROUGH S*N - (S-1)*L OF THE MATRIX A.
C        THE MATRIX SLAB OF THE DERIVATIVE CORRESPONDING TO THE K'TH
C        RIGHT HAND SIDE (FOR K=1,2,...,S) IS IN ROWS L+(K-1)*(N-L)+1
C        THROUGH L+K*(N-L).
C
C     ..................................................................
C
      INTEGER S, FIRSTCA, FIRSTCB, P, FIRSTR, INC(12, 8)
      DOUBLE PRECISION A(N, LPS), B(NDIM, PP2), ALF(NL), T(NMAX, IV), 
     X W(N), ACUM, ALPHA, BETA, RNORM, DSIGN, DSQRT, SAVE, R(N,S), 
     X U(L), XNORM, RI, Y(NMAX,S)
      LOGICAL NOWATE, PHILP1
      EXTERNAL ADA
      SAVE LP1, NCON, NCONP1, PHILP1, NOWATE, INC
C
      SAVE = 0
C
      LNLS = L+NL+S
      LNLS1 = LNLS+1
      LSP1 = L+S+1
      LPPS = LPPS1-1
      P = LPPS - L - S
C
      IF (ISEL .NE. 1) GO TO 3
         LP1 = L + 1
         FIRSTCA = 1
         LASTCA = LPS
         FIRSTCB = 1
         LASTCB = P
         FIRSTR = LP1
         CALL INIT(S, L, LMAX, NL, N, NMAX, NDIM, LPPS1, LPS, PP2, IV, 
     X   T, W, ALF, ADA, ISEL, IPRINT, A, B, INC, NCON, NCONP1, PHILP1, 
     X   NOWATE, GIDX)
         IF (ISEL .NE. 1) GO TO 99
         GO TO 30
C
    3 CALL ADA (S, LP1, NL, N, NMAX, NDIM, LPPS1, PP2, IV, A, B, 
     X INC, T, ALF, MIN0(ISEL,3), GIDX)
      IF (ISEL .EQ. 2) GO TO 6
C                                                 ISEL = 3 OR 4
      FIRSTCB = 1
      LASTCB = P
      FIRSTCA = 0
      FIRSTR = (4 - ISEL)*L + 1
      GO TO 50
C                                                 ISEL = 2
    6 FIRSTCA = NCONP1
      LASTCA = LPS
      FIRSTCB = 0
      IF (NCON .EQ. 0) GO TO 30
C     IF (A(1, NCON) .EQ. SAVE) GO TO 30
C        ISEL = -7
C        CALL VARERR (IPRINT, ISEL, NCON)
C        GO TO 99
C                                                  ISEL = 1 OR 2
   30 IF (PHILP1) GO TO 40
         DO 35 I=1,N
            DO 35 J=1,S
   35          R(I,J) = Y(I,J)
         GO TO 50
   40    DO 45 I=1,N
            RI = R(I,1)
            DO 45 J=1,S
   45          R(I,J) = Y(I,J) - RI
C                                             WEIGHT APPROPRIATE COLUMNS
   50 IF (NOWATE) GO TO 60
      DO 59 I = 1, N
         ACUM = W(I)
         IF (FIRSTCA .EQ. 0) GO TO 56
         DO 55 J = FIRSTCA, LASTCA
   55       A(I, J) = A(I, J) * ACUM
   56    IF (FIRSTCB .EQ. 0) GO TO 59
   57    DO 58 J = FIRSTCB, LASTCB
   58       B(I, J) = B(I, J) * ACUM
   59	 CONTINUE
   
C
C           COMPUTE ORTHOGONAL FACTORIZATIONS BY HOUSEHOLDER
C           REFLECTIONS.  IF ISEL = 1 OR 2, REDUCE PHI (STORED IN THE
C           FIRST L COLUMNS OF THE MATRIX A) TO UPPER TRIANGULAR FORM,
C           (Q*PHI = TRI), AND TRANSFORM Y (STORED IN COLUMNS L+1
C           THROUGH L+S), GETTING Q*Y = R.  IF ISEL = 1, ALSO TRANSFORM
C           J = D PHI (STORED IN COLUMNS L+S+1 THROUGH L+P+S OF THE
C           MATRIX A), GETTING Q*J = F.  IF ISEL = 3 OR 4, PHI HAS
C           ALREADY BEEN REDUCED, TRANSFORM ONLY J.  TRI, R, AND F
C           OVERWRITE PHI, Y, AND J, RESPECTIVELY, AND A FACTORED FORM
C           OF Q IS SAVED IN U AND THE LOWER TRIANGLE OF PHI.
C
   60 IF (L .EQ. 0) GO TO 75
      DO 70 K = 1, L
         KP1 = K + 1
         IF (ISEL .GE. 3 .OR. (ISEL .EQ. 2 .AND. K .LT.NCONP1)) GO TO 61
         ALPHA = DSIGN(XNORM(N+1-K, A(K, K)), A(K, K))
         U(K) = A(K, K) + ALPHA
         A(K, K) = -ALPHA
         FIRSTCA = KP1
         IF (ALPHA .NE. 0.0) GO TO 61
         ISEL = -8
         CALL VARERR (IPRINT, ISEL, K)
         GO TO 99
C                                        APPLY REFLECTIONS TO COLUMNS
C                                        FIRSTC TO LASTC.
   61    BETA = -A(K, K) * U(K)
C         
         IF (FIRSTCA .EQ. 0) GO TO 64
         DO 63 J = FIRSTCA, LASTCA
            ACUM = U(K)*A(K, J)
            DO 62 I = KP1, N
   62          ACUM = ACUM + A(I, K)*A(I, J)
            ACUM = ACUM / BETA
            A(K,J) = A(K,J) - U(K)*ACUM
            DO 63 I = KP1, N
   63          A(I, J) = A(I, J) - A(I, K)*ACUM
C   
   64 	    IF (FIRSTCB .EQ. 0) GO TO 70
            DO 66 J = FIRSTCB, LASTCB
            ACUM = U(K)*B(K, J)
            DO 65 I = KP1, N
   65          ACUM = ACUM + A(I, K)*B(I, J)
            ACUM = ACUM / BETA
            B(K,J) = B(K,J) - U(K)*ACUM
            DO 66 I = KP1, N
   66          B(I, J) = B(I, J) - A(I, K)*ACUM
   70		CONTINUE
C   
C
   75 IF (ISEL .GE. 3) GO TO 85
C
C           COMPUTE THE FROBENIUS NORM OF THE RESIDUAL MATRIX:
      RNORM = 0.
      DO 76 J=1,S
   76    RNORM = RNORM + XNORM(LN-L, R(P1,J))**2
      RNORM = DSQRT(RNORM)
C
      IF (ISEL .EQ. 2) GO TO 99
      IF (NCON .GT. 0) SAVE = A(1, NCON)
C
C           F2 IS NOW CONTAINED IN ROWS L+1 TO N AND COLUMNS L+S+1 TO
C           L+P+S OF THE MATRIX A.  NOW SOLVE THE S (L X L) UPPER
C           TRIANGULAR SYSTEMS TRI*BETA(J) = R1(J) FOR THE LINEAR
C           PARAMETERS BETA.  BETA OVERWRITES R1.
C
   85 IF (L .EQ. 0) GO TO 87
         DO 86 J=1,S
   86       CALL BACSUB(N,L,A,R(1,J))
C
C           MAJOR PART OF KAUFMAN'S SIMPLIFICATION OCCURS HERE.  COMPUTE
C           THE DERIVATIVE OF ETA WITH RESPECT TO THE NONLINEAR
C           PARAMETERS
C
C   T   D ETA        T    L          D PHI(J)    D PHI(L+1)
C  Q * --------  =  Q * (SUM BETA(J) --------  + ----------)  =  F2*BETA
C      D ALF(K)          J=1         D ALF(K)     D ALF(K)
C
C           AND STORE THE RESULT IN COLUMNS L+S+1 TO L+NL+S.  THE
C           FIRST L ROWS ARE OMITTED.  THIS IS -D(Q2)*Y.  THE RESIDUAL
C           R2 = Q2*Y (IN COLUMNS L+1 TO L+S) IS COPIED TO COLUMN
C           L+NL+S+1.
C
   87 DO 95 I = FIRSTR, N
         DO 95 ISBACK=1,S
            IS = S - ISBACK + 1
            ISUB = (N-L) * (IS-1) + I
            IF (L .EQ. NCON) GO TO 95
            M = 0
            DO 90 K=1,NL
               ACUM = 0.
               DO 88 J=NCONP1,L
                  IF (INC(K,J) .EQ. 0) GO TO 88
                  M = M+1
                  ACUM = ACUM + B(I,M) * R(J,IS)
   88             CONTINUE
               KSUB = LPS+K
               IF (INC(K,LP1) .EQ. 0) GO TO 90
               M = M+1
               ACUM = ACUM + B(I,M)
   90          B(ISUB,K) = ACUM
   95       B(ISUB,NL+1) = R(I,IS)

C   87 DO 95 ISBACK=1,S
C		 IS = S - ISBACK + 1
C         DO 95 I = FIRSTR, N
C            IF (L .EQ. NCON) GO TO 95                          
C				M = LPS                                      
C				DO 90 K = 1, NL                                 
C					ACUM = 0.                        
C					DO 88 J = NCONP1, L                  
C						IF (INC(K, J) .EQ. 0) GO TO 88        
C						M = M + 1                          
C						ACUM = ACUM + A(I, M) * R(J,IS)           
C   88					CONTINUE                                                  
C				KSUB = LPS + K                                               
C				IF (INC(K, LP1) .EQ. 0) GO TO 90                             
C				M = M + 1                                                    
C				ACUM = ACUM + A(I, M)                                        
C   90			A(I, KSUB) = ACUM                                            
C   95		A(I, LNLS1) = R(I,IS)
C
   99 RETURN
      END
C     ==============================================================
      DOUBLE PRECISION FUNCTION XNORM(N, X)
C     ==============================================================
C
C        COMPUTE THE L2 (EUCLIDEAN) NORM OF A VECTOR, MAKING SURE TO
C        AVOID UNNECESSARY UNDERFLOWS.  NO ATTEMPT IS MADE TO SUPPRESS
C        OVERFLOWS.
C
      DOUBLE PRECISION X(N), RMAX, SUM, TERM, DABS, DSQRT
C
C           FIND LARGEST (IN ABSOLUTE VALUE) ELEMENT
      RMAX = 0.
      DO 10 I = 1, N
         IF (DABS(X(I)) .GT. RMAX) RMAX = DABS(X(I))
   10    CONTINUE
C
      SUM = 0.
      IF (RMAX .EQ. 0.) GO TO 30
      DO 20 I = 1, N
         TERM = 0.
         IF (RMAX + DABS(X(I)) .NE. RMAX) TERM = X(I)/RMAX
   20    SUM = SUM + TERM*TERM
C
   30 XNORM = RMAX*DSQRT(SUM)
   99 RETURN
      END
