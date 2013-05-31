#include <cmath>
#include <algorithm>
#include "cminpack.h"

#include <stdio.h>

using namespace std;

#define TRUE_ (1)
#define FALSE_ (0)


void TestReducedJacobian(minpack_funcderstx_mn fcn, void *p, int m, int n, double *x, double *fjac,
                         int ldfjac, double *qtf, double *wa1, double *wa2, double *wa3, double *wa4)
{
   double temp;
   int iflag = 0;
   int i,j;

   double* fjac1 = new double[n*n]; 
   double e;

/*        compute the qr factorization of the jacobian matrix */
/*        calculated one row at a time, while simultaneously */
/*        forming (q transpose)*fvec and storing the first */
/*        n components in qtf. */

   int mskip = 1;

   double* qtf2 = new double[n];
   double* wa3_2 = new double[n];
   double* wa1_2 = new double[n];
   double* wa2_2 = new double[n];
   double* fjac2 = new double[n];

   qtf2--; wa3_2--; wa1_2--; wa2_2--; fjac2--;

   FILE* f = fopen("c:\\users\\scw09\\RED_JAC_TEST3.csv","a");

   if(f)
   {
      fprintf(f,"");
      for(i=0; i<n; i++)
         fprintf(f,"var %d,",i);
      for(i=0; i<n*n; i++)
         fprintf(f,"j_%d,",i);
      fprintf(f,"e,mskip\n");
   }
   /*
   for(int k=0; k<1; k++)
   {
      iflag = (*fcn)(p, m, n, 1, x, &temp, wa3, 0);
      iflag = 2;
      for (j = 0; j < n; ++j) {
         qtf[j] = qtf2[j] = 0.;
         for (i = 0; i < n; ++i) {
               fjac[i + j * ldfjac] = fjac2[i + j * ldfjac] = 0.;
         }
      }
      int m_max = m/2; //floor(((float)m)/mskip);
      for (i = 0; i < m_max+1; ++i) {
         (*fcn)(p, m, n, mskip, x, &temp, wa3, iflag);
         rwupdt(n, fjac, ldfjac, wa3, qtf, &temp,
                  wa1, wa2);
         ++iflag;
      }

      int m_max = floor(((float)m)/mskip);
      for (i = m_max; i < m; ++i) {
         (*fcn)(p, m, n, mskip, x, &temp, wa3_2, iflag);
         rwupdt(n, fjac2, ldfjac, wa3_2, qtf, &temp,
                  wa1_2, wa2_2);
         ++iflag;
      }

      for(i=0; i<n; i++) {
         rwupdt(n, fjac, ldfjac, fjac2+i*ldfjac, qtf, qtf+i, wa1, wa2);


      for(i=0; i<n*n; i++)
         fjac[i] *= sqrt(mskip);
      if (f)
      {
         for(i=0; i<n; i++)
            fprintf(f,"%e,",x[i]);
         fprintf(f,"   ");
         for(i=0; i<n*n; i++)
            fprintf(f,"%e,",fjac[i]);
      
               
         if (mskip==1)
         {
            memcpy(fjac1,fjac,n*n*sizeof(double));
            e = 0;
         }
         else
         {
            for(i=0; i<n*n; i++) 
               fjac[i]-=fjac1[i];
            e = enorm(n*n,fjac);
         }
      


         fprintf(f,"%f,%d\n",e,mskip);
      }
      
      mskip *= 4;
   }
   */

   if (f)
      fclose(f);


   delete[] fjac1;
}
