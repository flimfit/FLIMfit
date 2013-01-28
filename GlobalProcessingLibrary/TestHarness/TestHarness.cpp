#define BOOST_TEST_MODULE FLIMGlobalProcessingTest
#define BOOST_TEST_SHOW_PROGRESS yes
#define BOOST_TEST_AUTO_START_DBG yes

#include <boost/test/included/unit_test.hpp>
#include <boost/test/unit_test.hpp>

using namespace boost::unit_test;


#include <iostream>
#include <string>
#include <math.h>
#include "FLIMGlobalAnalysis.h"



void add_decay(int n_t, double* t, double tau, double I, float* decay)
{
   for(int i=0; i<n_t; i++)
      decay[i] += I * exp(-t[i]/tau);
}


BOOST_AUTO_TEST_CASE( FLIMTest )
{
   const int n_t   = 11;
   const int n_irf = 11;
   const int n_y   = 1;
   const int n_x   = 10;
   const int n_tau = 2;
   
   const double I0 = 1000;

   double t[n_t] = {0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000};
   double t_irf[n_irf] = {0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000};
   double tau[n_tau] = {3000, 2000};
   double t_int[n_t] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
   
   int t_skip = 0;


   float y[n_t * n_x * n_y];
   double irf[n_irf * n_x * n_y];
   memset(y, 0, n_t * n_x * n_y * sizeof(float));
   memset(irf, 0, n_t * n_x * n_y * sizeof(double));

   for(int i=0; i<n_x; i++)
   {
      double I = I0 * i/(n_x-1);
      add_decay(n_t, t, tau[0], I, y + i*n_t);
      add_decay(n_t, t, tau[1], I0-I, y + i*n_t);

      for(int j=0; j<i; j++)
         y[i*n_t+j] = 0;

      irf[i*n_t+i] = 1;
   }


   double fit[n_t * n_x];

   double tau_min[2] = {0, 0};
   double tau_max[2] = {10000, 10000};

   int id = FLIMGlobalGetUniqueID();

   double tau_guess[n_tau] = {2000, 4000};
   float tau_est[n_tau * n_x] = {0, 0, 0, 0};
   float beta_est[n_tau * n_x];
   float I0_est[n_tau * n_x];

   int e;
   int i0= 0;
   int n_valid;

   for(int i=0; i<2; i++)
   {
      int use_im = 1;
      
      e=SetupGlobalFit(id, 1, 1, n_irf, t_irf, irf, 0, NULL, 2, 0, 1, NULL, tau_min, tau_max, 1, tau_guess, 1, NULL, 0, 0, 0, 0, 0, 0, 0, 0, NULL, 0, 0, 0, NULL, 0, 1e-6/80.0, 0, 0, 0, 1, 0, 0, 0, NULL);
      BOOST_CHECK_EQUAL( e, 0 );
      
      e=SetDataParams(id, 1, n_x, n_y, 1, n_t, t, t_int, &t_skip, n_t, 0, &use_im, NULL, 0, 0, 1, 1, 0, 0);
      BOOST_CHECK_EQUAL( e, 0 );
      e=SetDataFloat(id, y);
      BOOST_CHECK_EQUAL( e, 0 );
     e=StartFit(id);
//      BOOST_CHECK_EQUAL( e, 0 );
      
//      e=GetResults(id, 0, NULL, NULL, tau_est, I0_est, beta_est, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
//      BOOST_CHECK_EQUAL( e, 0 );
      


      e=FLIMGlobalGetFit(id, 0, n_t, t, 1, &i0, fit, &n_valid); 
      BOOST_CHECK_EQUAL( e, 0 );
      
//      BOOST_CHECK( tau_est[0] - tau[0] < 5 );
//      BOOST_CHECK( tau_est[1] - tau[1] < 5 );

//      for(int i=0; i<n_t; i++)
//         BOOST_CHECK( beta_est[i] >= 0 && beta_est[i] <= 1 );
   }
   
   FLIMGlobalClearFit(id);
    
}


/*
int main()
{

   double t[11] = {0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000};
   float y[22] = {1000.0f, 0606.5f, 0367.9f, 0223.1f, 0135.3f, 0082.1f, 0049.8f, 0030.2f, 0018.3f, 0011.1f, 0006.7f,
                  1000.0f, 0606.5f, 0367.9f, 0223.1f, 0135.3f, 0082.1f, 0049.8f, 0030.2f, 0018.3f, 0011.1f, 0006.7f};
   double t_int[11] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

   double fit[22];

   double t_irf[3] = {-1, 0, 1};
   double irf[6]   = {0, 1, 0, 0, 1, 0};
   int t_skip = 0;
   int use_im = 1;

   double tau_min[2] = {0, 0};
   double tau_max[2] = {10000, 10000};

   int id = FLIMGlobalGetUniqueID();

   double tau_guess[2] = {2000, 4000};
   float tau_est[4] = {0, 0, 0, 0};
   float beta_est[4];
   float I0_est[4];
   int ierr[2];

   int e;
   char buf[1000];
   int i0= 0;


   for(int i=0; i<2; i++)
   {

      OutputDebugString("===================================================\n");
      OutputDebugString("[*] Setting Fit Parameters\n");
      e=SetupGlobalFit(id, 1, 1, 3, t_irf, irf, 0, 1, 0, tau_min, tau_max, 1, tau_guess, 1, NULL, 0, 0, 0, 0, 0, 0, 0, 0, NULL, 0, 0, 0, NULL, 0, 1e-6/80.0, 0, 0, 0, ierr, 1, 0, 0, NULL);
      OutputDebugString("[*] Setting Data Parameters\n");
      e=SetDataParams(id, 1, 2, 1, 1, 11, t, t_int, &t_skip, 11, 0, &use_im, NULL, 0, 0, 1, 0, 0);
      OutputDebugString("[*] Setting Data\n");
      e=SetDataFloat(id, y);
      OutputDebugString("[*] Starting Fit\n");
      e=StartFit(id);
      OutputDebugString("[*] Getting Results\n");
      e=GetResults(id, 0, NULL, NULL, tau_est, I0_est, beta_est, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
      sprintf(buf,"    |  Tau: %f, %f\n    | Beta: %f, %f\n    | ierr: %d\n",tau_est[0],tau_est[1],I0_est[0],I0_est[1],ierr[0]);
      OutputDebugString(buf);
      OutputDebugString("[*] Getting Fit\n");
      e=FLIMGlobalGetFit(id, 0, 11, t, 1, &i0, fit); 
      
      
   }

   OutputDebugString("===================================================\n");
   return 0;



}
*/