
//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

/*
#define BOOST_TEST_MODULE FLIMfitTest
#define BOOST_TEST_SHOW_PROGRESS yes
#define BOOST_TEST_LOG_LEVEL all
#define BOOST_TEST_AUTO_START_DBG yes
#define BOOST_TEST_RESULT_CODE no
*/
//#include <boost/test/included/unit_test.hpp>
//#include <boost/test/unit_test.hpp>

#include "FLIMSimulation.h"

#include <iostream>
#include <string>
#include <cmath>
#include "FLIMGlobalFitController.h"
#include "MultiExponentialDecayGroup.h"


//using namespace boost::unit_test;

void add_decay(int n_t, double* t, double tau, double I, float* decay)
{
   for(int i=0; i<n_t; i++)
      decay[i] += (float) (I * exp(-t[i]/tau));
}

bool CheckResult( int n_stats, int n_params, int n_regions, const char** param_names, vector<float>& data, const char* param, int region, float expected_value, float rel_tol )
{
   if (region >= n_regions)
      return false;
   
   for (int i=0; i<n_params; i++)
   {
      if (strcmp(param_names[i], param)==0)
      {
         float fitted = data[ n_stats * n_params * region * i + PARAM_MEAN ];
         float std = data[ n_stats * n_params * region * i + PARAM_STD ];
         float diff   = fitted - expected_value;
         float rel    = fabs( diff ) / expected_value;
         bool pass = (rel <= rel_tol);
         
         printf( "Compare %s, Region %d:\n", param, region );
         printf( "   | Expected  : %f\n", expected_value );
         printf( "   | Fitted    : %f\n", fitted );
         printf( "   | Std D.    : %f\n", std );
         printf( "   | Rel Error : %f\n", rel );
         
         if (pass)
            printf( "   | PASS\n");
         else
            printf( "   | FAIL\n");
         
         return ( pass );
      }
   }
   
   printf("FAIL: Expected parameter %s not found", param);
   
   return false;
}


//BOOST_AUTO_TEST_CASE(TCSPC_Single)

int main()
{
   FLIMSimulationTCSPC sim;


   vector<double> irf;
   vector<float>  image_data;
   vector<double> t;
   vector<double> t_int;

   int n_x = 10;
   int n_y = 10;

   int N = 10000;
   double tau = 2000;


   sim.GenerateIRF(N, irf);
   sim.GenerateImage(tau, N, n_x, n_y, image_data);
   sim.GenerateImage(500, N, n_x, n_y, image_data);

   int n_t = sim.GetTimePoints(t, t_int);
   int n_irf = n_t;

   // Data Parameters
   //===========================
   vector<int> use_im(n_x, 1);
   int t_skip = 0;
   int n_trim_end = 0;
   int n_regions_expected = 1;


   int use_image_irf = false;


   // Parameters for fitting
   //===========================
   double tau_min[1] = { 0.0 };
   double tau_max[1] = { 1e6 };
   double tau_guess[1] = { 2000 };

   double t0 = 0;

   int algorithm = ALG_ML;
   int global_mode = MODE_PIXELWISE;

   int data_type = DATA_TYPE_TCSPC;
   bool polarisation_resolved = false;

   int n_chan = 1;


   auto irf_ = std::make_shared<InstrumentResponseFunction>();
   irf_->SetIRF(n_irf, n_chan, t[0], t[1] - t[0], irf.data());

   AcquisitionParameters acq(data_type, t_rep_default, polarisation_resolved, n_chan);
   acq.SetT(t);
   acq.SetIRF(irf_);
   acq.SetImageSize(n_x, n_y);
   
   auto data = std::make_shared<FLIMData>();
   data->SetAcquisitionParmeters(acq);
   data->SetNumImages(1);

   auto model = std::make_shared<DecayModel>();
   model->SetAcquisitionParameters(data);
   auto group = std::make_shared<MultiExponentialDecayGroup>(2);
   model->AddDecayGroup(group);


   FLIMGlobalFitController controller;   
   controller.SetFitSettings(FitSettings(algorithm));
   controller.SetModel(model);

   controller.SetData(data);
   data->SetData(image_data.data());

   controller.Init();
   controller.RunWorkers();
   
   
   /*
   // Start Fit
   //===========================
   int id = FLIMGlobalGetUniqueID();

   e = SetupGlobalFit(id, global_mode, use_image_irf, n_irf, &(t[0]), &(irf[0]), 0, NULL, 1, 0, 1, NULL, tau_min, tau_max, 0, tau_guess, 1, NULL, 0, t0, 0, 0, 0, 0, 0, 0, NULL, 0, 0, 0, NULL, 1, 12.5e3, 0, 0, algorithm, 0, 0, 0.95, 0, 0, 0, NULL);
   BOOST_CHECK_EQUAL(e, 0);

   e = SetDataParams(id, 1, n_x, n_y, 1, n_t, &(t[0]), &(t_int[0]), &t_skip, n_t - t_skip - n_trim_end, DATA_TYPE_TIMEGATED, &use_im[0], NULL, 0, 0, 4096, 1, global_mode, 0, 0);
   BOOST_CHECK_EQUAL(e, 0);

   e = SetDataFloat(id, &image_data[0]);
   BOOST_CHECK_EQUAL(e, 0);

   e = StartFit(id);
   BOOST_CHECK_EQUAL(e, 0);


   int n_regions_total = GetTotalNumOutputRegions(id);
   BOOST_CHECK_EQUAL(n_regions_total, n_regions_expected);

   int n_output_params;
   const char** names = GetOutputParamNames(id, &n_output_params);

   int n_stats = 11;

   // Result storage
   int n_regions;
   vector<int>   image((n_regions_total));
   vector<int>   regions((n_regions_total));
   vector<int>   region_size((n_regions_total));
   vector<float> success((n_regions_total));
   vector<int>   iterations((n_regions_total));
   vector<float> stats((n_output_params * n_regions_total * n_stats));

   BOOST_ASSERT(n_regions_total > 0);

   e = GetImageStats(id, &n_regions, &image[0], &regions[0], &region_size[0], &success[0], &iterations[0], &stats[0]);
   BOOST_CHECK_EQUAL(e, 0);

   BOOST_CHECK(CheckResult(n_stats, n_output_params, n_regions, names, stats, "tau_1", 0, (float)tau, 0.01f));
   //e=FLIMGlobalGetFit(id, 0, n_t, t, 1, &i0, fit, &n_valid);

   FLIMGlobalClearFit(-1);
   */
}

/*
BOOST_AUTO_TEST_CASE( TCSPC_Single )
{
   int e;

   FLIMSimulationTCSPC sim;
   
   
   vector<double> irf;
   vector<float>  image_data;
   vector<double> t;
   vector<double> t_int;

   int n_x = 10;
   int n_y = 10;

   int N = 10000;
   double tau = 1000;
   
   
   sim.GenerateIRF(N, irf);
   sim.GenerateImage(tau, N, n_x, n_y, image_data);

   int n_t = sim.GetTimePoints(t, t_int);
   int n_irf = n_t;
   
   // Data Parameters
   //===========================
   vector<int> use_im(n_x, 1);
   int t_skip = 0;
   int n_trim_end = 0;
   int n_regions_expected = 1;


   int use_image_irf = false;
   
   
   // Parameters for fitting
   //===========================
   double tau_min[1]   = {0.0};
   double tau_max[1]   = {1e6};
   double tau_guess[1] = {2000};
   
   double t0 = 0;

   int algorithm   = ALG_ML;
   int global_mode = MODE_PIXELWISE;

   // Start Fit
   //===========================
   int id = FLIMGlobalGetUniqueID();
   
   e = SetupGlobalFit(id, global_mode, use_image_irf, n_irf, &(t[0]), &(irf[0]), 0, NULL, 1, 0, 1, NULL, tau_min, tau_max, 0, tau_guess, 1, NULL, 0, t0, 0, 0, 0, 0, 0, 0, NULL, 0, 0, 0, NULL, 1, 12.5e3, 0, 0, algorithm, 0, 0, 0.95, 0, 0, 0, NULL);
   BOOST_CHECK_EQUAL( e, 0 );
    
   e=SetDataParams(id, 1, n_x, n_y, 1, n_t, &(t[0]), &(t_int[0]), &t_skip, n_t-t_skip-n_trim_end, DATA_TYPE_TIMEGATED, &use_im[0], NULL, 0, 0, 4096, 1, global_mode, 0, 0);
   BOOST_CHECK_EQUAL( e, 0 );
   
   e=SetDataFloat(id, &image_data[0]);
   BOOST_CHECK_EQUAL( e, 0 );
   
   e=StartFit(id);
   BOOST_CHECK_EQUAL( e, 0 );
   
   
   int n_regions_total = GetTotalNumOutputRegions(id);
   BOOST_CHECK_EQUAL( n_regions_total, n_regions_expected );
   
   int n_output_params;
   const char** names = GetOutputParamNames(id, &n_output_params);
   
   int n_stats = 11;
   
   // Result storage
   int n_regions;
   vector<int>   image( (n_regions_total) );
   vector<int>   regions( (n_regions_total) );
   vector<int>   region_size( (n_regions_total) );
   vector<float> success( (n_regions_total) );
   vector<int>   iterations( (n_regions_total) );
   vector<float> stats( (n_output_params * n_regions_total * n_stats) );
   
   BOOST_ASSERT( n_regions_total > 0 );

   e=GetImageStats(id, &n_regions, &image[0], &regions[0], &region_size[0], &success[0], &iterations[0], &stats[0]);
   BOOST_CHECK_EQUAL( e, 0 );
   
   BOOST_CHECK( CheckResult( n_stats, n_output_params, n_regions, names, stats, "tau_1", 0, (float) tau, 0.01f ) );
   //e=FLIMGlobalGetFit(id, 0, n_t, t, 1, &i0, fit, &n_valid);

   FLIMGlobalClearFit(-1);
}
*/
/*
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
//   float beta_est[n_tau * n_x];
//   float I0_est[n_tau * n_x];

   int e;
   int i0= 0;
   int n_valid;

   for(int i=0; i<2; i++)
   {
      int use_im = 1;
      
      e=SetupGlobalFit(id, 1, 1, n_irf, t_irf, irf, 0, NULL, 2, 0, 1, NULL, tau_min, tau_max, 1, tau_guess, 1, NULL, 0, 0, 0, 0, 0, 0, 0, 0, NULL, 0, 0, 0, NULL, 0,
                       1e-6/80.0, 0, 0, 0, 0, 1, 0.95, 0, 0, 0, NULL);
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
*/

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
