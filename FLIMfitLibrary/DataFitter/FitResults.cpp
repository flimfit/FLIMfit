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

#include "FitResults.h"
#include "FLIMData.h"
#include "util.h"
#include "TrimmedMean.h"
#include "RegionStats.h"
#include "RegionStatsCalculator.h"

#include <algorithm>
#include <limits>

using std::max;
using std::min;





FitResults::FitResults(shared_ptr<DecayModel> model, shared_ptr<FLIMData> data, int calculate_errors) :
   model(model), data(data), calculate_errors(calculate_errors)
{
   n_px = data->n_masked_px;
   lmax = model->GetNumColumns();
   nl   = model->GetNumNonlinearVariables();
   n_meas = data->getNumMeasurements();
   n_im = data->n_im_used;
   n_regions = data->getNumOutputRegionsTotal();
   
   
   n_nl_output_params = nl; // TODO - redundant?

   pixelwise = (data->global_mode == MODE_PIXELWISE);

   DetermineParamNames();
   
   stats.SetSize(n_regions, n_output_params);
   region_summary.resize(n_regions);


   int alf_size;
   
   if (pixelwise)
      alf_size = n_px;
   else
      alf_size = n_regions;
   alf_size *= nl;

   int lin_size = n_px * lmax;

   n_aux = data->getNumAuxillary();
   int aux_size = n_aux * n_px;

   mask.resize(n_im);

   lin_params.resize(lin_size, std::numeric_limits<float>::quiet_NaN());
   chi2.resize(n_px, std::numeric_limits<float>::quiet_NaN());
   aux_data.resize(aux_size, std::numeric_limits<float>::quiet_NaN());

   ierr.resize(n_regions);
   success.resize(n_regions);
   alf.resize(alf_size, std::numeric_limits<float>::quiet_NaN());
   
   if (calculate_errors)
   {
      alf_err_lower.resize(alf_size);
      alf_err_upper.resize(alf_size);
   }
}

FitResults::~FitResults()
{
}


const FitResultsRegion FitResults::GetRegion(int image, int region)
{
   return FitResultsRegion(this, image, region);
}

const FitResultsRegion FitResults::GetPixel(int image, int region, int pixel)
{
   return FitResultsRegion(this, image, region, pixel);
}


void FitResults::GetNonLinearParams(int image, int region, int pixel, vector<double>& params)
{
   int idx;
   if (pixelwise)
      idx = data->getRegionPos(image, region) + pixel;
   else
      idx = data->getRegionIndex(image, region);

   params.resize(nl);

   for(int i=0; i<nl; i++)
      params[i] = alf[idx*nl + i];
}

void FitResults::GetLinearParams(int image, int region, int pixel, vector<float>& params)
{
   int start = data->getRegionPos(image, region) + pixel;

   params.resize(lmax);
   for (int i = 0; i<lmax; i++)
      params[i] = lin_params[start*lmax + i];
}


float* FitResults::GetAuxDataPtr(int image, int region)
{
   int pos =  data->getRegionPos(image,region);
   return aux_data.data() + pos * n_aux;
}

void FitResults::GetPointers(int image, int region, int pixel, float*& non_linear_params, float*& linear_params, float*& chi2_)
{

   int start = data->getRegionPos(image, region) + pixel;

   int idx;
   if (pixelwise)
      idx = start;
   else
      idx = data->getRegionIndex(image, region);

   non_linear_params = alf.data() + idx * nl;
   linear_params     = lin_params.data() + start * lmax;
   chi2_             = chi2.data() + start;

}

void FitResults::SetFitStatus(int image, int region, int code)
{
   int r_idx = data->getRegionIndex(image, region);

   if (pixelwise)
   {
      if (code >= 0)
      {
         success[r_idx] += 1;
         ierr[r_idx] += code;
      }
   }
   else
   {
      ierr[r_idx] = code;
      success[r_idx] = (float) min(0, code);
   }

}

void FitResults::DetermineParamNames()
{
   model->GetOutputParamNames(param_names, n_nl_output_params, n_lin_output_params);
   data->getAuxParamNames(param_names);
   param_names.push_back("chi2");

   n_output_params = (int) param_names.size();

   param_names_ptr.assign(n_output_params,0);

   for(int i=0; i<n_output_params; i++)
      param_names_ptr[i] = param_names[i].c_str();
}

int FitResults::GetNumX() { assert(false); return 0; } // TODO
int FitResults::GetNumY() { assert(false); return 0; } // TODO


void FitResultsRegion::GetPointers(float*& non_linear_params, float*& linear_params,  float*& chi2)
{
   results->GetPointers(image, region, pixel, non_linear_params, linear_params, chi2);
}

void FitResultsRegion::SetFitStatus(int code)
{
   results->SetFitStatus(image, region, code);
}


void FitResults::ComputeRegionStats(float confidence_factor)
{
   RegionStatsCalculator stats_calculator(n_aux, confidence_factor);
   
   vector<float> param_buf;
   
   for (int im = 0; im<n_im; im++)
   {
      /*
      float* param_buf = param_buf_ + buf_size * thread;
      float* err_lower_buf = err_lower_buf_ + buf_size * thread;
      float* err_upper_buf = err_upper_buf_ + buf_size * thread;

      float* nl_output = nl_output_ + n_nl_output_params * n_px * thread;
      float* err_lower_output = err_lower_output_ + n_nl_output_params * n_px * thread;
      float* err_upper_output = err_upper_output_ + n_nl_output_params * n_px * thread;
      

      float* nan_buf = nan_buf_ + nl * thread;
      */

      for (int rg = 1; rg<MAX_REGION; rg++)
      {
         int r_idx = data->getRegionIndex(im, rg);
         int idx = data->getOutputRegionIndex(im, rg);

         if (r_idx > -1)
         {

            int start = data->getRegionPos(im, rg);
            int s_local = data->getRegionCount(im, rg);
            float* intensity = aux_data.data() + start;

            if (param_buf.size() < n_output_params*s_local)
               param_buf.resize(n_output_params*s_local);

            
            //int intensity_stride = n_aux;

            region_summary[idx].image = data->use_im[im];
            region_summary[idx].region = rg;
            region_summary[idx].size = s_local;
            region_summary[idx].iterations = ierr[r_idx];
            region_summary[idx].success = success[r_idx];

            if (data->global_mode == MODE_PIXELWISE)
               region_summary[idx].success /= s_local;

            int output_idx = 0;

            if (data->global_mode == MODE_PIXELWISE)
            {
               float* alf_group = alf.data() + start * nl;
             
               for (int i = 0; i < s_local; i++)
                  output_idx += model->GetNonlinearOutputs(alf_group + i*nl, param_buf.data() + output_idx);

               stats_calculator.CalculateRegionStats(n_nl_output_params, s_local, param_buf.data(), intensity, stats, idx);
            }
            else
            {
               float* alf_group = alf.data() + nl * r_idx;

               model->GetNonlinearOutputs(alf_group, param_buf.data());

               for (int i = 0; i<n_nl_output_params; i++)
                  stats.SetNextParam(idx, param_buf[i]);
            }
            
            for(int i=0; i<s_local; i++)
               model->GetLinearOutputs(lin_params.data() + (start+i)*lmax, param_buf.data() + i*n_lin_output_params);
            
            stats_calculator.CalculateRegionStats(n_lin_output_params, s_local, param_buf.data(), intensity, stats, idx);
            stats_calculator.CalculateRegionStats(n_aux, s_local, aux_data.data(), intensity, stats, idx);
            stats_calculator.CalculateRegionStats(1, s_local, chi2.data() + start, intensity, stats, idx);
         }
      }
   }

}
/*
int FitResults::GetImageStats(int& n_regions, int image[], int regions[], int region_size[], float success[], int iterations[], float params[], double conf_factor, int n_thread)
{
   INIT_CONCURRENCY;

   using namespace std;

   int n_px = data->n_px;

   int nl = model->nl;

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   START_SPAN("Calculating Result Statistics");
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   ImageStats<float> stats(data->n_output_regions_total, n_output_params, params);

   //   _ASSERTE( _CrtCheckMemory( ) );

   int buf_size = max(n_px, n_nl_output_params) * 2;

   float* param_buf_ = new float[buf_size * n_thread];
   float* err_lower_buf_ = new float[buf_size * n_thread];
   float* err_upper_buf_ = new float[buf_size * n_thread];

   float* nl_output_ = NULL;
   float* err_lower_output_ = NULL;
   float* err_upper_output_ = NULL;
   if (data->global_mode == MODE_PIXELWISE)
   {
      nl_output_ = new float[n_nl_output_params * n_px * n_thread];
      err_lower_output_ = new float[n_nl_output_params * n_px * n_thread];
      err_upper_output_ = new float[n_nl_output_params * n_px * n_thread];
   }

   float* nan_buf_ = new float[nl * n_thread];
   SetNaN(nan_buf_, nl * n_thread);

   omp_set_num_threads(n_thread);



   //#pragma omp parallel for
   for (int im = 0; im<data->n_im_used; im++)
   {
      int thread = omp_get_thread_num();

      float *alf_group, *lin_group;
      float *alf_err_lower_group, *alf_err_upper_group;

      float* param_buf = param_buf_ + buf_size * thread;
      float* err_lower_buf = err_lower_buf_ + buf_size * thread;
      float* err_upper_buf = err_upper_buf_ + buf_size * thread;

      float* nl_output = nl_output_ + n_nl_output_params * n_px * thread;
      float* err_lower_output = err_lower_output_ + n_nl_output_params * n_px * thread;
      float* err_upper_output = err_upper_output_ + n_nl_output_params * n_px * thread;

      float* nan_buf = nan_buf_ + nl * thread;

      for (int rg = 1; rg<MAX_REGION; rg++)
      {
         int r_idx = data->GetRegionIndex(im, rg);
         int idx = data->GetOutputRegionIndex(im, rg);

         if (r_idx > -1)
         {

            int start = data->GetRegionPos(im, rg);
            int s_local = data->GetRegionCount(im, rg);
            float* intensity = aux_data + start;

            image[idx] = data->use_im[im];
            regions[idx] = rg;
            region_size[idx] = s_local;
            iterations[idx] = ierr[r_idx];
            success[idx] = this->success[r_idx];

            if (data->global_mode == MODE_PIXELWISE)
               success[idx] /= s_local;

            if (data->global_mode == MODE_PIXELWISE)
            {
               alf_group = alf + start * nl;

               if (calculate_errors)
               {
                  alf_err_lower_group = alf_err_lower + start * nl;
                  alf_err_upper_group = alf_err_upper + start * nl;

                  for (int i = 0; i<s_local; i++)
                     model->ProcessNonLinearParams(alf_group + i*nl, alf_err_lower_group + i*nl, alf_err_upper_group + i*nl,
                     nl_output + i*n_nl_output_params, err_lower_output + i*n_nl_output_params, err_upper_output + i*n_nl_output_params);
               }
               else
               {

                  for (int i = 0; i<s_local; i++)
                     model->ProcessNonLinearParams(alf_group + i*nl, nan_buf, nan_buf,
                     nl_output + i*n_nl_output_params, err_lower_output + i*n_nl_output_params, err_upper_output + i*n_nl_output_params);
               }

               CalculateRegionStats(n_nl_output_params, s_local, nl_output, intensity, n_aux, stats, idx, conf_factor, param_buf);
            }
            else
            {
               alf_group = alf + nl * r_idx;


               if (calculate_errors)
               {
                  alf_err_lower_group = alf_err_lower + nl * r_idx;
                  alf_err_upper_group = alf_err_upper + nl * r_idx;

                  model->ProcessNonLinearParams(alf_group, alf_err_lower_group, alf_err_upper_group,
                     param_buf, err_lower_buf, err_upper_buf);

                  for (int i = 0; i<n_nl_output_params; i++)
                     stats.SetNextParam(idx, param_buf[i], err_lower_buf[i], err_upper_buf[i]);
               }
               else
               {
                  model->ProcessNonLinearParams(alf_group, nan_buf, nan_buf,
                     param_buf, err_lower_buf, err_upper_buf);

                  for (int i = 0; i<n_nl_output_params; i++)
                     stats.SetNextParam(idx, param_buf[i]);
               }
            }


            lin_group = lin_params + start * lmax;

            CalculateRegionStats(lmax, s_local, lin_group, intensity, n_aux, stats, idx, conf_factor, param_buf);
            CalculateRegionStats(n_aux, s_local, aux_data, intensity, n_aux, stats, idx, conf_factor, param_buf);
            CalculateRegionStats(1, s_local, chi2 + start, intensity, n_aux, stats, idx, conf_factor, param_buf);

         }
      }
   }

   //  _ASSERTE( _CrtCheckMemory( ) );


   n_regions = data->n_output_regions_total;

   ClearVariable(nl_output_);
   ClearVariable(err_lower_output_);
   ClearVariable(err_upper_output_);
   ClearVariable(param_buf_);
   ClearVariable(err_lower_buf_);
   ClearVariable(err_upper_buf_);
   ClearVariable(nan_buf_);

   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   END_SPAN;
   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   return 0;

}
*/

int FitResults::GetParameterImage(int im, int param, uint8_t ret_mask[], float image_data[])
{

   int start, s_local;
   int r_idx;

   int nl = n_nl_output_params;

   vector<float> buffer(n_output_params);

   float* param_data = NULL;
   int span;

   if (param < 0 || param >= n_output_params
      || im    < 0 || im >= data->n_im)
      return -1;

   // Get mask
   vector<uint8_t>& im_mask = mask[im];
   int n_px = (int) im_mask.size();
   
   if (ret_mask)
      memcpy(ret_mask, im_mask.data(), n_px * sizeof(uint8_t));

   int merge_regions = data->merge_regions;
   int iml = data->getImLoc(im);
   im = iml;
   if (iml == -1)
      return 0;

   SetNaN(image_data, n_px);

   for (int rg = 1; rg<MAX_REGION; rg++)
   {
      int r_param = param;

      r_idx = data->getRegionIndex(im, rg);

      start = data->getRegionPos(im, rg);
      s_local = data->getRegionCount(im, rg);


      if (r_idx > -1)
      {

         if (r_param < n_nl_output_params)
         {
            if (data->global_mode == MODE_PIXELWISE)
            {
               param_data = alf.data() + start * nl;

               int j = 0;
               for (int i = 0; i<n_px; i++)
                  if (im_mask[i] == rg || (merge_regions && im_mask[i] > rg))
                  {
                     model->GetNonlinearOutputs(param_data + j*nl, buffer.data());
                     image_data[i] = buffer[r_param];
                     j++;
                  }

            }
            else
            {
               param_data = alf.data() + r_idx * nl;
               model->GetNonlinearOutputs(param_data, buffer.data());
               float p = buffer[r_param];

               for (int i = 0; i<n_px; i++)
                  if (im_mask[i] == rg || (merge_regions && im_mask[i] > rg))
                     image_data[i] = p;

            }
         }
         else
         {
            r_param -= n_nl_output_params;

            span = 1;

            if (r_param < lmax)
            {
               param_data = lin_params.data() + start * lmax + r_param;
               span = lmax;
            } r_param -= lmax;


            if (r_param < n_aux)
            {
               param_data = aux_data.data() + start * n_aux + r_param;
               span = n_aux;
            } r_param -= n_aux;

            if (r_param == 0)
               param_data = chi2.data() + start;
            r_param -= 1;

            int j = 0;
            if (param_data != NULL)
               for (int i = 0; i<n_px; i++)
                  if (im_mask[i] == rg || (merge_regions && im_mask[i] > rg))
                     image_data[i] = param_data[span*(j++)];
         }

      }
   }

   return 0;
}
