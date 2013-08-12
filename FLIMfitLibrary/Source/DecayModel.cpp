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

#include "util.h"

void DecayModel::Init()
{
   use_kappa      = true;

 
      
   tau_start = inc_donor ? 0 : 1;

   beta_global = (fit_beta != FIT_LOCALLY);

   if (polarisation_resolved)
   {
      n_chan = 2;
      n_r = n_theta + inc_rinf;
      n_pol_group = n_r + 1;
   }
   else
   {
      n_chan = 1;
      n_pol_group = 1;
      n_r = 0;
   }

   n_theta_v = n_theta - n_theta_fix;

   n_fret_v = n_fret - n_fret_fix;
   n_fret_group = n_fret + inc_donor;        // Number of decay 'groups', i.e. FRETing species + no FRET

   n_v = n_exp - n_fix;                      // Number of unfixed exponentials
   
   n_exp_phi = (beta_global ? n_decay_group : n_exp);
   
   n_beta = (fit_beta == FIT_GLOBALLY) ? n_exp - n_decay_group : 0;

   n_meas = n_t * n_chan;



   SetupPolarisationChannelFactors();
   SetupDecayGroups();
   CheckGateSpacing();

   SetParameterIndices();
   SetOutputParamNames();


   // Select correct convolution function for data type
   //-------------------------------------------------
   if (data->data_type == DATA_TYPE_TCSPC)
   {
      Convolve = conv_irf_tcspc;
      ConvolveDerivative = ref_reconvolution ? conv_irf_deriv_ref_tcspc : conv_irf_deriv_tcspc;
   }
   else
   {
      Convolve = conv_irf_timegate;
      ConvolveDerivative = ref_reconvolution ? conv_irf_deriv_ref_timegate : conv_irf_deriv_timegate;
   }

   // Setup adjust buffer which will be subtracted from the data
   SetupAdjust(0, adjust_buf, (fit_scatter == FIX) ? (float) scatter_guess : 0, 
                              (fit_offset == FIX)  ? (float) offset_guess  : 0, 
                              (fit_tvb == FIX)     ? (float) tvb_guess     : 0);

}

DecayModel::~DecayModel()
{
   AlignedClearVariable(exp_buf);
}

void DecayModel::SetupDecayGroups()
{
   decay_group_buf = new int[n_exp];

   if (beta_global)
   {

      // Check to make sure that decay groups increase
      // contiguously from zero
      int cur_group = 0;
      if (decay_group != NULL)
      {
         for(int i=0; i<n_exp; i++)
         {
            if (decay_group[i] == (cur_group + 1))
            {
               cur_group++;
            }
            else if (decay_group[i] != cur_group)
            {
               decay_group = NULL;
               break;
            }
         }
      }
   }
   else
   {
      decay_group = NULL;
      n_decay_group = 1;
   }

   if (decay_group == NULL)
      for(int i=0; i<n_exp; i++)
         decay_group_buf[i] = 0;
   else
      for(int i=0; i<n_exp; i++)
         decay_group_buf[i] = decay_group[i];
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


void DecayModel::AllocateBuffers()
{
   try
   {
      cur_alf      = new double[ nl ]; //ok
      /*
      #ifdef _WINDOWS
         exp_buf   = (double*) _aligned_malloc( n_thread * n_fret_group * exp_buf_size * sizeof(double), 16 ); //ok
       #else
         exp_buf   = new double[n_thread * n_fret_group * exp_buf_size];
       #endif
       */
      AlignedAllocate( n_thread * n_fret_group * exp_buf_size, exp_buf ); 
      
      tau_buf      = new double[ n_thread * (n_fret+1) * n_exp ]; //free ok 
      beta_buf     = new double[ n_thread * n_exp ]; //free ok
      theta_buf    = new double[ n_thread * n_theta ]; //free ok 
      adjust_buf   = new float[ n_meas ]; // free ok 

   }
   catch(std::exception e)
   {
      error =  ERR_OUT_OF_MEMORY;
      CleanupTempVars();
      CleanupResults();
      return;
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

void DecayModel::SetupAdjust(int thread, float adjust[], float scatter_adj, float offset_adj, float tvb_adj)
{

   double scale_fact[2];
   scale_fact[0] = 1;
   scale_fact[1] = 0;

   for(int i=0; i<n_meas; i++)
      adjust[i] = 0;

   add_irf(thread, 0, adjust, n_r, scale_fact);

   for(int i=0; i<n_meas; i++)
      adjust[i] = adjust[i] * scatter_adj + offset_adj;

   if (tvb_profile != NULL)
   {
      for(int i=0; i<n_meas; i++)
         adjust[i] += (float) (tvb_profile[i] * tvb_adj);
   }

   for(int i=0; i<n_meas; i++)
      adjust[i] = adjust[i] *= photons_per_count;
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

   if (fit_offset == FIT_GLOBALLY)
      alf_offset_idx = idx++;

  if (fit_scatter == FIT_GLOBALLY)
      alf_scatter_idx = idx++;

  if (fit_tvb == FIT_GLOBALLY)
      alf_tvb_idx = idx++;

  if (ref_reconvolution == FIT_GLOBALLY)
     alf_ref_idx = idx++;


}


void DecayModel::SetOutputParamNames()
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
   
   if (fit_offset == FIT_GLOBALLY)
      param_names.push_back("offset");

   if (fit_scatter == FIT_GLOBALLY)
      param_names.push_back("scatter");

   if (fit_tvb == FIT_GLOBALLY)
      param_names.push_back("tvb");

   if (ref_reconvolution == FIT_GLOBALLY)
      param_names.push_back("tau_ref");

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
   
   // Parameters we manually calculate at the end
   
   param_names.push_back("I");

   if ( acceptor != NULL )
      param_names.push_back("acceptor");

   if (polarisation_resolved)
      param_names.push_back("r_ss");


   if (calculate_mean_lifetimes)
   {
      param_names.push_back("mean_tau");
      param_names.push_back("w_mean_tau");
   }

   param_names.push_back("chi2");

   n_output_params = (int) param_names.size();

   param_names_ptr = new const char*[n_output_params];

   for(int i=0; i<n_output_params; i++)
      param_names_ptr[i] = param_names[i].c_str();

}


void DecayModel::CalculateParameterCount()
{
   nl  = n_v + n_fret_v + n_beta + n_theta_v;                                // (varp) Number of non-linear parameters to fit
   p   = (n_v + n_beta)*n_fret_group*n_pol_group + n_exp_phi * n_fret_v + n_theta_v;    // (varp) Number of elements in INC matrix 
   l   = n_exp_phi * n_fret_group * n_pol_group;          // (varp) Number of linear parameters


   if (ref_reconvolution == FIT_GLOBALLY) // fitting reference lifetime
   {
      nl++;
      p += l;
   }

   // Check whether t0 has been specified
   if (fit_t0)
   {
      nl++;
      p += l;
   }

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

}



/** 
 * Calculate IRF values to include in convolution for each time point
 *
 * Accounts for the step function in the model - we don't want to convolve before the decay starts
*/
void DecayModel::CalculateIRFMax(int n_t, double t[])
{
   for(int j=0; j<n_chan; j++)
   {
      for(int i=0; i<n_t; i++)
      {
         irf_max[j*n_t+i] = 0;
         int k=0;
         while(k < n_irf && (t[i] - t_irf[k] - t0_guess) >= -1.0)
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
   

   // Get reference to timepoints
   double* t = data->GetT();
   
   // Get IRF for the pixel position idx
   double *irf = this->irf_buf + idx * n_irf * n_chan;

   //===================================================
   // If we have a scatter IRF use data after cumulative sum of IRF is
   // 95% of total sum (so we ignore any potential tail etc)
   //===================================================
   if (!ref_reconvolution)
   {      
      // Determine 95% of IRF
      double irf_95 = 0;
      for(int i=0; i<n_irf; i++)
         irf_95 += irf[i];
      irf_95 *= 0.95;
   
      // Cycle through IRF to find time at which cumulative IRF is 95% of sum.
      // Once we get there, find the time gate in the data immediately after this time
      c = 0;
      for(int i=0; i<n_irf; i++)
      {
         c += irf[i];
         if (c >= irf_95)
         {
            for (int j=j_last; j<data->n_t; j++)
               if (t[j] > t_irf[i])
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
         if (irf[i] > c)
         {
            c = irf[i];
            for (int j=j_last; j<data->n_t; j++)
               if (t[j] > t_irf[i])
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

void DecayModel::SetInitialParameters(double param[], double mean_arrival_time)
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

   idx = n_v;

   for(int j=0; j<n_v; j++)
      param[idx++] = TransformRange(param[j],tau_min[j+n_fix],tau_max[j+n_fix]);

   if(fit_beta == FIT_GLOBALLY)
      for(int j=0; j<n_exp-1; j++)
         if (decay_group_buf[j+1] == decay_group_buf[j])
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

   if(ref_reconvolution == FIT_GLOBALLY)
      param[idx++] = ref_lifetime_guess;
}