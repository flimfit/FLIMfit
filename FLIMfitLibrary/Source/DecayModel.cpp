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

#include "DecayModel.h"
#include "IRFConvolution.h"
#include "ModelADA.h"

#include <stdio.h>
#include "util.h"

#include <complex>
#include <algorithm>

using std::abs;
using std::max;

DecayModel::DecayModel(const ModelParameters& params, const AcquisitionParameters& acq, shared_ptr<InstrumentResponseFunction> irf) : 
   ModelParameters(params), 
   AcquisitionParameters(acq), 
   irf(irf), 
   init(false),
   chan_fact(NULL),
   constrain_nonlinear_parameters(true)
{
}

void DecayModel::Init()
{
   constrain_nonlinear_parameters = true;
   
   n_irf = irf->n_irf;

   CalculateParameterCounts();      

   SetupPolarisationChannelFactors();
   SetupDecayGroups();
   CheckGateSpacing();

   SetParameterIndices();

   CalculateIRFMax();
   ma_start = DetermineMAStartPosition(0);

   // Setup adjust buffer which will be subtracted from the data
   SetupAdjust();

   photons_per_count = (float) (1.0/counts_per_photon); // we use this quite a lot

}

DecayModel::~DecayModel()
{
   ClearVariable(chan_fact);
}

void DecayModel::CalculateParameterCounts()
{
   tau_start = inc_donor ? 0 : 1;

   beta_global = (fit_beta != FIT_LOCALLY);
   calculate_mean_lifetimes = !beta_global && n_exp > 1;


   if (polarisation_resolved)
   {
      n_chan = 2;
      n_r = n_theta + inc_rinf;
      n_pol_group = n_r + 1;
   }
   else
   {
      n_chan = 1;
      n_r = 0;
      n_pol_group = 1;
   }

   n_theta_v = n_theta - n_theta_fix;

   n_fret_v = n_fret - n_fret_fix;
   n_fret_group = n_fret + inc_donor;        // Number of decay 'groups', i.e. FRETing species + no FRET

   n_v = n_exp - n_fix;                      // Number of unfixed exponentials
   
   n_exp_phi = (beta_global ? n_decay_group : n_exp);
   
   n_beta = (fit_beta == FIT_GLOBALLY) ? n_exp - n_decay_group : 0;

   n_meas = n_t * n_chan;

   n_stray = (fit_offset == FIT_LOCALLY) + (fit_scatter == FIT_LOCALLY) + (fit_tvb == FIT_LOCALLY);
   


   nl  = n_v + n_fret_v + n_beta + n_theta_v;                                // (varp) Number of non-linear parameters to fit
   p   = (n_v + n_beta)*n_fret_group*n_pol_group + n_exp_phi * n_fret_v + n_theta_v;    // (varp) Number of elements in INC matrix 
   l   = n_exp_phi * n_fret_group * n_pol_group;          // (varp) Number of linear parameters


   if (irf->ref_reconvolution == FIT_GLOBALLY) // fitting reference lifetime
   {
      nl++;
      p += l;
   }

   /*
   // Check whether t0 has been specified
   if (fit_t0)
   {
      nl++;
      p += l;
   }
   */

   if (fit_offset == FIT_GLOBALLY)
   {
      nl++;
      p++;
   }

   if (fit_scatter == FIT_GLOBALLY)
   {
      nl++;
      p++;
   }

   if (fit_tvb == FIT_GLOBALLY)
   {
      nl++;
      p++;
   }

   if (fit_offset == FIT_LOCALLY)
   {
      l++;
   }

   if (fit_scatter == FIT_LOCALLY)
   {
      l++;
   }

   if (fit_tvb == FIT_LOCALLY)
   {
      l++;
   }

   lmax = l;

   if (calculate_mean_lifetimes)
      lmax += 2;


}

void DecayModel::SetupDecayGroups()
{
}

void DecayModel::SetupPolarisationChannelFactors()
{
   if (polarisation_resolved)
   {
      chan_fact = new double[ n_chan * n_pol_group ]; //free ok
      int i;

      double f = +0.00;

      chan_fact[0] = 1.0/3.0- f*1.0/3.0;
      chan_fact[1] = (1.0/3.0) + f*1.0/3.0;

      for(i=1; i<n_pol_group ; i++)
      {
         chan_fact[i*2  ] =   2.0/3.0 - f*2.0/3.0;
         chan_fact[i*2+1] =  -(1.0/3.0) + f*2.0/3.0;
      }
   }
   else
   {
      chan_fact = new double[1]; //free ok
      chan_fact[0] = 1;
   }
}

void DecayModel::CheckGateSpacing()
{
   // Check to see if gates are equally spaced
   //---------------------------------------------
   eq_spaced_data = true;
   double dt0 = t[1]-t[0];
   for(int i=2; i<n_t; i++)
   {
      double dt = t[i] - t[i-1];
      if (abs(dt - dt0) > 1)
      {
         eq_spaced_data = false;
         break;
      }
         
   }
}

void DecayModel::SetupAdjust()
{
   float scatter_adj = (fit_scatter == FIX) ? (float) scatter_guess : 0;
   float offset_adj  = (fit_offset == FIX)  ? (float) offset_guess  : 0; 
   float tvb_adj     = (fit_tvb == FIX)     ? (float) tvb_guess     : 0;
                              
   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   adjust_buf.assign(n_meas, 0);

   vector<double> irf_buf( n_irf * n_meas );

   AddIRF(&irf_buf[0], 0, 0, &adjust_buf[0], n_r, scale_fact); // TODO : irf_shift?

   for(int i=0; i<n_meas; i++)
      adjust_buf[i] = adjust_buf[i] * scatter_adj + offset_adj;

   if (!tvb_profile.empty())
   {
      for(int i=0; i<n_meas; i++)
         adjust_buf[i] += (float) (tvb_profile[i] * tvb_adj);
   }

   for(int i=0; i<n_meas; i++)
      adjust_buf[i] *= photons_per_count;
}



void DecayModel::SetParameterIndices()
{
   // Set alf indices
   //-----------------------------
   int idx = n_v;

   if (fit_beta == FIT_GLOBALLY)
   {
     alf_beta_idx = idx;
     idx += n_beta;
   }

   if (fit_fret == FIT)
   {
     alf_E_idx = idx;
     idx += n_fret_v;
   }

   alf_theta_idx = idx; 
   idx += n_theta_v;

   if (fit_t0)
      alf_t0_idx = idx++;

   if (irf->ref_reconvolution == FIT_GLOBALLY)
      alf_ref_idx = idx++;

   if (fit_offset == FIT_GLOBALLY)
      alf_offset_idx = idx++;

  if (fit_scatter == FIT_GLOBALLY)
      alf_scatter_idx = idx++;

  if (fit_tvb == FIT_GLOBALLY)
      alf_tvb_idx = idx++;



}


void DecayModel::NormaliseLinearParams(volatile float lin_params[], float non_linear_params[], volatile float norm_params[])
{
   int idx;

   if (polarisation_resolved)
   {
      for(int j=0; j<n_stray; j++)
         norm_params[j] = lin_params[j];

      lin_params  += n_stray;
      norm_params += n_stray;

      float I0 = lin_params[0];
      float r0 = 0;

      for(int j=1; j<n_r+1; j++)
      {
         norm_params[j] = lin_params[j] / I0;
         r0 += norm_params[j];
      }

      norm_params[0]     = r0;
      norm_params[n_r+1] = I0;

      idx = n_r + 2;
   }
   else
   {
      int n_j = fit_fret ? n_fret_group : n_exp_phi;

      for(int j=0; j<n_stray; j++)
        norm_params[j] = lin_params[j]; 

      lin_params  += n_stray;
      norm_params += n_stray;

      float I0 = 0;
      for(int j=0; j<n_j; j++)
         I0 += lin_params[j];

      if (n_j > 1)
      {
         for (int j=0; j<n_j; j++)
            norm_params[j] = lin_params[j] / I0;
         norm_params[n_j] = I0; 
      }

      idx = n_j + 1;

   }

   CalculateMeanLifetime(lin_params, non_linear_params, norm_params + idx);
}

void DecayModel::DenormaliseLinearParams(volatile float norm_params[], volatile float lin_params[])
{
   float I0;
   
   for(int i=0; i<n_stray; i++)
      lin_params[i] = norm_params[i]; 

   lin_params += n_stray;
   norm_params += n_stray;

   if (polarisation_resolved)
   {
      I0 = norm_params[n_r+1]; 

      lin_params[0] = I0;
         
      for(int j=1; j<n_r+1; j++)
         lin_params[j] = norm_params[j] * I0;

         
      norm_params += lmax;
      lin_params += lmax;
   }
   else
   {
      int n_j = fit_fret ? n_fret_group : n_exp_phi;

      I0 = norm_params[n_j];

      if (n_j > 1)
         for (int j=0; j<n_j; j++)
            lin_params[j] = norm_params[j] * I0;
      else
         lin_params[0] = norm_params[0];
             
      lin_params += lmax;
      norm_params += lmax;
   }
}



void DecayModel::CalculateMeanLifetime(volatile float lin_params[], float tau[], volatile float mean_lifetimes[])
{
   if (calculate_mean_lifetimes)
   {
      float mean_tau   = 0;
      float w_mean_tau = 0;
      
      for (int i=0; i<n_fix; i++)
      {
         w_mean_tau += (float) (tau_guess[i] * tau_guess[i] * lin_params[i]);
         mean_tau   += (float) (               tau_guess[i] * lin_params[i]);
      }

      for (int i=0; i<n_v; i++)
      {
         w_mean_tau += (float) (tau[i] * tau[i] * lin_params[i+n_fix]);
         mean_tau   += (float) (         tau[i] * lin_params[i+n_fix]); 
      }

      w_mean_tau /= mean_tau;  

      mean_lifetimes[0] = mean_tau;
      mean_lifetimes[1] = w_mean_tau;
   }

}


void DecayModel::GetOutputParamNames(vector<string>& param_names, int& n_nl_output_params)
{
   char buf[1024];

   // Parameters associated with non-linear parameters (or fixed)

   for(int i=0; i<n_exp; i++)
   {
      sprintf(buf,"tau_%i",i+1);
      param_names.push_back(buf);
   }

   if (fit_beta != FIT_LOCALLY)
      for(int i=0; i<n_exp; i++)
      {
         sprintf(buf,"beta_%i",i+1);
         param_names.push_back(buf);
      }

   for(int i=0; i<n_fret; i++)
   {
      sprintf(buf,"E_%i",i+1);
      param_names.push_back(buf);
   }

   for(int i=0; i<n_theta; i++)
   {
      sprintf(buf,"theta_%i",i+1);
      param_names.push_back(buf);
   }

   if (fit_t0)
      param_names.push_back("t0");

   if (irf->ref_reconvolution == FIT_GLOBALLY)
      param_names.push_back("tau_ref");

   if (fit_offset == FIT_GLOBALLY)
      param_names.push_back("offset");

   if (fit_scatter == FIT_GLOBALLY)
      param_names.push_back("scatter");

   if (fit_tvb == FIT_GLOBALLY)
      param_names.push_back("tvb");

   n_nl_output_params = (int) param_names.size();

   if (fit_offset == FIT_LOCALLY)
      param_names.push_back("offset");

   if (fit_scatter == FIT_LOCALLY)
      param_names.push_back("scatter");

   if (fit_tvb == FIT_LOCALLY)
      param_names.push_back("tvb");

   // Now that parameters that are derived from the linear parameters

   if (fit_beta == FIT_LOCALLY && n_exp > 1)
      for(int i=0; i<n_exp; i++)
      {
         sprintf(buf,"beta_%i",i+1);
         param_names.push_back(buf);
      }

   if (n_decay_group > 1)
      for(int i=0; i<n_decay_group; i++)
      {
         sprintf(buf,"gamma_%i",i+1);
         param_names.push_back(buf);
      }

   if (fit_fret == FIT && inc_donor)
   {
      sprintf(buf,"gamma_0");
      param_names.push_back(buf);
   }

   if (n_fret_group > 1)
      for(int i=0; i<n_fret; i++)
      {
         sprintf(buf,"gamma_%i",i+1);
         param_names.push_back(buf);
      }

   if (polarisation_resolved)
      param_names.push_back("r_0");

   for(int i=0; i<n_theta; i++)
   {
      sprintf(buf,"r_%i",i+1);
      param_names.push_back(buf);
   }

   param_names.push_back("I0");
   

   if (calculate_mean_lifetimes)
   {
      param_names.push_back("mean_tau");
      param_names.push_back("w_mean_tau");
   }

   param_names.push_back("chi2");

}



/** 
 * Calculate IRF values to include in convolution for each time point
 *
 * Accounts for the step function in the model - we don't want to convolve before the decay starts
*/
void DecayModel::CalculateIRFMax()
{
   double* t = GetT();

   irf_max.assign(n_meas, 0);

   double t0 = irf->GetT0();
   double dt_irf = irf->timebin_width;

   for(int j=0; j<n_chan; j++)
   {
      for(int i=0; i<n_t; i++)
      {
         int k=0;
         while(k < n_irf && (t[i] - t0 - k*dt_irf) >= -1.0)
         {
            irf_max[j*n_t+i] = k + j*n_irf;
            k++;
         }
      }
   }

}


/**
 * Determine which data should be used when we're calculating the average lifetime for an initial guess. 
 * Since we won't take the IRF into account we need to only use data after the gate is mostly closed.
 * 
 * \param idx The pixel index, used if we have a spatially varying IRF
*/
int DecayModel::DetermineMAStartPosition(int idx)
{
   double c;
   int j_last = 0;
   int start = 0;

   vector<double> storage(n_meas);
   double *lirf = irf->GetIRF(idx, 0, &(storage[0]));
   double t_irf0 = irf->GetT0();
   double dt_irf = irf->timebin_width;

   //===================================================
   // If we have a scatter IRF use data after cumulative sum of IRF is
   // 95% of total sum (so we ignore any potential tail etc)
   //===================================================
   if (!irf->ref_reconvolution)
   {      
      // Determine 95% of IRF
      double irf_95 = 0;
      for(int i=0; i<n_irf; i++)
         irf_95 += lirf[i];
      irf_95 *= 0.95;
   
      // Cycle through IRF to find time at which cumulative IRF is 95% of sum.
      // Once we get there, find the time gate in the data immediately after this time
      c = 0;
      for(int i=0; i<n_irf; i++)
      {
         c += lirf[i];
         if (c >= irf_95)
         {
            for (int j=j_last; j<n_t; j++)
               if (t[j] > t_irf0 + i*dt_irf)
               {
                  start = j;
                  j_last = j;
                  break;
               }
            break;
         }   
      }
   }

   //===================================================
   // If we have reference IRF, use data after peak of reference which should roughly
   // correspond to end of gate
   //===================================================
   else
   {
      // Cycle through IRF, if IRF is larger then previously seen find the find the 
      // time gate in the data immediately after this time. Repeat until end of IRF.
      c = 0;
      for(int i=0; i<n_irf; i++)
      {
         if (lirf[i] > c)
         {
            c = lirf[i];
            for (int j=j_last; j<n_t; j++)
               if (t[j] > t_irf0 + i*dt_irf)
               {
                  start = j;
                  j_last = j;
                  break;
               }
         }
      }
   }


   return start;
}

void DecayModel::SetInitialParameters(vector<double>& param, double mean_arrival_time)
{
   int idx = 0;

   // Estimate lifetime from mean arrival time if requested
   //------------------------------
   if (estimate_initial_tau)
   {

      if (n_v == 1)
      {
         param[0] = mean_arrival_time;
      }
      else if (n_v > 1)
      {
         double min_tau  = 0.5*mean_arrival_time;
         double max_tau  = 1.5*mean_arrival_time;
         double tau_step = (max_tau - min_tau)/(n_v-1);

         for(int i=0; i<n_v; i++)
            param[i] = max_tau-i*tau_step;
      }
   }
   else
   {
      for(int i=0; i<n_v; i++)
         param[i] = tau_guess[n_fix+i];
   }

   for(int j=0; j<n_v; j++)
      param[idx++] = TransformRange(param[j],tau_min[j+n_fix],tau_max[j+n_fix]);

   if(fit_beta == FIT_GLOBALLY)
      for(int j=0; j<n_exp-1; j++)
         if (decay_group[j+1] == decay_group[j])
            param[idx++] = fixed_beta[j];

   for(int j=0; j<n_fret_v; j++)
      param[idx++] = E_guess[j+n_fret_fix];

   for(int j=0; j<n_theta_v; j++)
      param[idx++] = TransformRange(theta_guess[j+n_theta_fix],0,1000000);
   
   if(fit_t0)
      param[idx++] = t0_guess;
      
   if(fit_offset == FIT_GLOBALLY)
      param[idx++] = offset_guess;

   if(fit_scatter == FIT_GLOBALLY)
      param[idx++] = scatter_guess;

   if(fit_tvb == FIT_GLOBALLY) 
      param[idx++] = tvb_guess;

   if(irf->ref_reconvolution == FIT_GLOBALLY)
      param[idx++] = irf->ref_lifetime_guess;
}


/**
 * Estimate average lifetime of a decay as an intial guess
 */
double DecayModel::EstimateAverageLifetime(float decay[], int data_type)
{
   double  tau = 0;
   int     start;

   //if (image_irf)
   //   start = DetermineMAStartPosition(p);
   //else
      start = ma_start;

   //===================================================
   // For TCSPC data, calculate the mean arrival time and apply a correction for
   // the data censoring (i.e. finite measurement window)
   //===================================================

   if (data_type == DATA_TYPE_TCSPC)
   {
      double t_mean = 0;
      double  n  = 0;
      double c;

      for(int i=start; i<n_t; i++)
      {
         c = decay[i]-adjust_buf[i];
         t_mean += c * (t[i] - t[start]);
         n   += c;
      }

      // If polarisation resolevd add perp decay using I = para + 2*g*perp
      if (polarisation_resolved)
      {
         for(int i=start; i<n_t; i++)
         {
            t_mean += 2 * irf->g_factor * decay[i+n_t] * (t[i] - t[start]);
            n   += 2 * irf->g_factor * decay[i+n_t];
         }
      }

      t_mean = t_mean / n;

      // Apply correction for measurement window
      double T = t[n_t-1]-t[start];

      // Older iterative correction; tends to same value more slowly
      //tau = t_mean;
      //for(int i=0; i<10; i++)
      //   tau = t_mean + T / (exp(T/tau)-1);

      t_mean /= T;
      tau = t_mean;

      // Newton-Raphson update
      for(int i=0; i<3; i++)
      {
         double e = exp(1/tau);
         double iem1 = 1/(e-1);
         tau = tau - ( - tau + t_mean + iem1 ) / ( e * iem1 * iem1 / (tau*tau) - 1 );
      }
      tau *= T;
   }

   //===================================================
   // For widefield data, apply linearised model
   //===================================================

   else
   {
      double sum_t  = 0;
      double sum_t2 = 0;
      double sum_tlnI = 0;
      double sum_lnI = 0;
      double dt;
      int    N;

      double log_di;

      N = n_t-start;

      for(int i=start; i<n_t; i++)
      {
         dt = t[i]-t[start];

         sum_t += dt;
         sum_t2 += dt * dt;

         if ((decay[i]-adjust_buf[i]) > 0)
            log_di = log((decay[i]-adjust_buf[i])/t_int[i]);
         else
            log_di = 0;

         sum_tlnI += dt * log_di;
         sum_lnI  += log_di;

      }

      tau  = - (N * sum_t2   - sum_t * sum_t);
      tau /=   (N * sum_tlnI - sum_t * sum_lnI);

   }

   return tau;

}



DecayModelWorkingBuffers::DecayModelWorkingBuffers(shared_ptr<DecayModel> model) :
   AcquisitionParameters(*model), first_eval(true)
{

   int max_dim, exp_buf_size;

   irf = model->irf;

   pulsetrain_correction = model->pulsetrain_correction;
   n_pol_group = model->n_pol_group;
   n_fret_group = model->n_fret_group;
   irf_max = &(model->irf_max[0]);
   n_irf = irf->n_irf;

   max_dim = max(n_irf,n_t);
   max_dim = (int) (ceil(max_dim/4.0) * 4);

   n_exp = model->n_exp;
   exp_dim = max_dim * n_chan;
   
   exp_buf_size = n_exp * model->n_fret_group * model->n_pol_group * exp_dim * N_EXP_BUF_ROWS;

   AlignedAllocate( exp_buf_size, exp_buf ); 
      
   tau_buf   = new double[ (model->n_fret+1) * model->n_exp ]; //free ok 
   beta_buf  = new double[ model->n_exp ]; //free ok
   theta_buf = new double[ model->n_theta ]; //free ok 
   irf_buf   = new double[ model->n_irf * model->n_chan ];
   cur_alf   = new double[ model->nl ]; //ok



   this->model = model;

}

DecayModelWorkingBuffers::~DecayModelWorkingBuffers()
{
   delete[] cur_alf;
   delete[] tau_buf;
   delete[] beta_buf;
   delete[] theta_buf;
   delete[] irf_buf;

   AlignedClearVariable(exp_buf);
}