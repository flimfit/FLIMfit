#ifndef _QRTEST_
#define _QRTEST_

#ifdef _WIN32

#include <boost/random/normal_distribution.hpp>
#include <boost/random/mersenne_twister.hpp>
#include "cminpack.h"
#include <vector>
#include "omp_stub.h"
#include <algorithm>


#ifdef _WIN32
#undef WIN32_LEAN_AND_MEAN
#include <Windows.h>
#undef min
#undef max
#else
//#include <boost/timer/timer.hpp>
#include <iostream>
#endif



using std::vector;
using boost::random::normal_distribution;


/* for lmstx1 and lmstx */
/*         if iflag = 1 calculate the functions at x and */
/*         return this vector in fvec. */
/*         if iflag = i calculate the (i-1)-st row of the */
/*         jacobian at x and return this vector in fjrow. */
/* return a negative value to terminate lmstr1/lmstr */
int fcn(void *p, int m, int n, int s_red, const double *x, double *fnorm,
                                     double *fjrow, int iflag, int thread )
{
   double** p1 = (double**) p;

   double* J = p1[0];
   double* f = p1[1];

   int row = iflag - 3;

   memcpy(fjrow, J+row*n, n*sizeof(double));
   *fnorm = f[row];
   
   return 0;

}


void QR_test(int n, int m, int rep, double times[])
{

   long t;
   boost::mt19937 gen;
   normal_distribution<double>norm_dist = normal_distribution<double>(0, 100);
   gen.seed( 0 );
   

   vector<double> J(m*n);
   vector<double> f(m);

   double* J1 = new double[m*n];
   double* f1 = new double[m];

   for(int i=0; i<m*n; i++)
      J[i] = norm_dist(gen);
   for(int i=0; i<m; i++)
      f[i] = norm_dist(gen);

#ifdef _WIN32
   t = GetTickCount();
#endif
    
   vector<double> rb(rep+1); // to prevent optimisation out

   for(int k=0; k<rep; k++)
   {
      memcpy(J1, J.data(), m*n*sizeof(double));
      memcpy(f1, f.data(), m*sizeof(double));

      //rb[k] = J1[k % m];
      //rb[k+1] = f1[k % m];
   }
    
#ifdef _WIN32
    long dt_0 = GetTickCount()-t;
#endif

   // Householder
   //==================================================

   vector<double> rdiag(n);
   vector<double> acnorm(n);
   vector<double> work(n);
   vector<double> qtf(n);
   vector<int> pvt(n);

#ifdef _WIN32
   t = GetTickCount();
#endif

   for(int k=0; k<rep; k++)
   {
      memcpy(J1, J.data(), m*n*sizeof(double));
      memcpy(f1, f.data(), m*sizeof(double));

      qrfac(m, n, J1, m, true, pvt.data(), n, rdiag.data(), acnorm.data(), work.data());
      
        for (int j = 0; j < n; ++j) {
            if (J1[j + j * n] != 0.) {
                double sum = 0.;
                for (int i = j; i < m; ++i) {
                    sum += J1[i + j * n] * f1[i];
                }
                double temp = -sum / J1[j + j * n];
                for (int i = j; i < m; ++i) {
                    f1[i] += J1[i + j * n] * temp;
                }
            }
            qtf[j] = f1[j];
        }
        
   }
   
    long dt_h;
#ifdef _WIN32
   dt_h = GetTickCount()-t-dt_0;
#endif

//   printf("\n\nHouseholder: %d s\n",dt_h);



   

   // Givens
   //==================================================

   vector<double> cos(n);
   vector<double> sin(n);
   vector<double> b(n);
   vector<double> r(n*n);
   double alpha;

#ifdef _WIN32
   t = GetTickCount();
#endif
    
   for(int k=0; k<rep; k++)
   {
      memcpy(J1, J.data(), m*n*sizeof(double));
      memcpy(f1, f.data(), m*sizeof(double));

      for(int i=0; i<m; i++)
      {
         double* w = &J1[n*i];
         alpha = f1[i];
         rwupdt(n, r.data(), n, w, b.data(), &alpha, cos.data(), sin.data());
      }
   }
    long dt_g;
    
#ifdef _WIN32
    dt_g = GetTickCount()-t-dt_0;
#endif

//   printf("Givens     : %d s\n",dt_g);


   // Combined
   //==================================================
   long dt_hg[5];
   for(int n_thread=1; n_thread<=4; n_thread*=2)
   {
   
      int ldfjac = n;
       int n_jac_group = std::min(m/n_thread,1024);

       n_jac_group = std::max(n_jac_group,4);
      //n_jac_group = 1024;
   
       int dim = std::max(16,n);

      omp_set_num_threads(n_thread);
      qtf.assign(n_thread*dim,0);

      vector<double> wa1(dim * n_thread);
      vector<double> wa2(dim * n_thread);
      vector<double> wa3(dim * n_thread * n * n_jac_group);
      vector<double> fjac(dim * dim * n_thread);
      vector<double> fvec(n * n_thread * n_jac_group);

#ifdef _WIN32
      t = GetTickCount();
#endif

      for(int k=0; k<rep; k++)
      {
         //vector<double> J1 = J;
         //vector<double> f1 = f;


         vector<double*> p(2);
         p[0] = J.data();
         p[1] = f.data();

         factorise_jacobian(fcn, p.data(), 1, n, m, n_jac_group, NULL, fvec.data(), fjac.data(), n, qtf.data(), wa1.data(), wa2.data(), wa3.data(), n_thread);
      }


#ifdef _WIN32
      dt_hg[n_thread] = GetTickCount()-t-dt_0;
#endif
   }
//   printf("Combined   : %d s\n",dt_hg);


   times[0] = ((double)dt_h) / rep;
   times[1] = ((double)dt_g) / rep;
   times[2] = ((double)dt_hg[1]) / rep;
   times[3] = ((double)dt_hg[2]) / rep;
   times[4] = ((double)dt_hg[4]) / rep;

}


#endif

#endif