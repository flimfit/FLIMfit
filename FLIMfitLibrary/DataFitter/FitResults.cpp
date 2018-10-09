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





FitResults::FitResults(std::shared_ptr<DecayModel> model, std::shared_ptr<FLIMData> data, int calculate_errors) :
   model(model), data(data), calculate_errors(calculate_errors)
{
   n_px = data->n_masked_px;
   lmax = model->getNumColumns();
   nl   = model->getNumNonlinearVariables();
   n_meas = data->getNumMeasurements();
   n_im = data->n_im_used;
   n_regions = data->getNumOutputRegionsTotal();
   
   n_nl_output_params = nl;

   pixelwise = (data->global_scope == Pixelwise);

   determineParamNames();
  
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

   image_size.resize(n_im);
   for (int i = 0; i < n_im; i++)
   {
      image_size[i] = data->getImageSize(i);
   }
}

FitResults::~FitResults()
{
}


const FitResultsRegion FitResults::getRegion(int image, int region)
{
   return FitResultsRegion(this, image, region);
}

const FitResultsRegion FitResults::getPixel(int image, int region, int pixel)
{
   return FitResultsRegion(this, image, region, pixel);
}


void FitResults::getNonLinearParams(int image, int region, int pixel, std::vector<double>& params)
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

void FitResults::getLinearParams(int image, int region, int pixel, std::vector<float>& params)
{
   int start = data->getRegionPos(image, region) + pixel;

   params.resize(lmax);
   for (int i = 0; i<lmax; i++)
      params[i] = lin_params[start*lmax + i];
}


float_iterator FitResults::getAuxDataPtr(int image, int region)
{
   int pos =  data->getRegionPos(image,region);
   return aux_data.begin() + pos * n_aux;
}

void FitResults::getPointers(int image, int region, int pixel, float_iterator& non_linear_params, float_iterator& linear_params, float_iterator& chi2_)
{

   int start = data->getRegionPos(image, region) + pixel;

   int idx;
   if (pixelwise)
      idx = start;
   else
      idx = data->getRegionIndex(image, region);

   non_linear_params = alf.begin() + idx * nl;
   linear_params     = lin_params.begin() + start * lmax;
   chi2_             = chi2.begin() + start;

}

void FitResults::setFitStatus(int image, int region, int code)
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

void FitResults::determineParamNames()
{
   model->getOutputParamNames(param_names, param_group, n_nl_output_params, n_lin_output_params);
   
   auto data_names = data->getAuxParamNames();
   for (auto& name : data_names)
   {
      param_names.push_back(name);
      param_group.push_back(0);
   }

   param_names.push_back("chi2");
   param_group.push_back(0);

   n_output_params = (int) param_names.size();

   param_names_ptr.assign(n_output_params,0);

   for(int i=0; i<n_output_params; i++)
      param_names_ptr[i] = param_names[i].c_str();
}

int FitResults::getParamIndex(const std::string& param_name)
{
   for (int i = 0; i < param_names.size(); i++)
      if (param_names[i] == param_name)
         return i;
   return -1;
}

int FitResults::getNumX(int im) { return image_size[im].width; } 
int FitResults::getNumY(int im) { return image_size[im].height; }


void FitResultsRegion::getPointers(float_iterator& non_linear_params, float_iterator& linear_params, float_iterator& chi2)
{
   results->getPointers(image, region, pixel, non_linear_params, linear_params, chi2);
}

void FitResultsRegion::setFitStatus(int code)
{
   results->setFitStatus(image, region, code);
}


void FitResults::computeRegionStats(float confidence_factor)
{
   stats.SetSize(n_regions, n_output_params);
   region_summary.resize(n_regions);

   RegionStatsCalculator stats_calculator(n_aux, confidence_factor);
   
   std::vector<float> param_buf;
   
   for (int im = 0; im<n_im; im++)
   {
      for (int rg = 1; rg<MAX_REGION; rg++)
      {
         int r_idx = data->getRegionIndex(im, rg);
         int idx = data->getOutputRegionIndex(im, rg);

         if (r_idx > -1)
         {

            int start = data->getRegionPos(im, rg);
            int s_local = data->getRegionCount(im, rg);
            auto intensity = aux_data.begin() + start;

            if (param_buf.size() < n_output_params*s_local)
               param_buf.resize(n_output_params*s_local);

            
            //int intensity_stride = n_aux;

            region_summary[idx].image = data->use_im[im];
            region_summary[idx].region = rg;
            region_summary[idx].size = s_local;
            region_summary[idx].iterations = ierr[r_idx];
            region_summary[idx].success = success[r_idx];

            if (data->global_scope == Pixelwise)
               region_summary[idx].success /= s_local;

            int output_idx = 0;

            if (data->global_scope == Pixelwise)
            {
               auto alf_group = alf.begin() + start * nl;
             
               for (int i = 0; i < s_local; i++)
                  output_idx += model->getNonlinearOutputs(alf_group + i*nl, param_buf.begin() + output_idx);

               stats_calculator.CalculateRegionStats(n_nl_output_params, s_local, param_buf.begin(), intensity, stats, idx);
            }
            else
            {
               auto alf_group = alf.begin() + nl * r_idx;

               model->getNonlinearOutputs(alf_group, param_buf.begin());

               for (int i = 0; i<n_nl_output_params; i++)
                  stats.SetNextParam(idx, param_buf[i]);
            }
            
            for(int i=0; i<s_local; i++)
               model->getLinearOutputs(lin_params.begin() + (start+i)*lmax, param_buf.begin() + i*n_lin_output_params);
            
            stats_calculator.CalculateRegionStats(n_lin_output_params, s_local, param_buf.begin(), intensity, stats, idx);
            stats_calculator.CalculateRegionStats(n_aux, s_local, aux_data.begin(), intensity, stats, idx);
            stats_calculator.CalculateRegionStats(1, s_local, chi2.begin() + start, intensity, stats, idx);
         }
      }
   }

}


int FitResults::getParameterImage(int im, int param, uint8_t ret_mask[], float image_data[])
{

   int start, s_local;
   int r_idx;

   std::vector<float> buffer(n_output_params);

   float_iterator param_data;
   int span;

   if (param < 0 || param >= n_output_params)
      throw std::runtime_error("Invalid parameter index");

   if (im < 0 || im >= data->n_im)
      throw std::runtime_error("Invalid dataset index");

   // Get mask
   std::vector<mask_type>& im_mask = mask[im];
   int n_px = (int) im_mask.size();
   
   if (ret_mask)
      memcpy(ret_mask, im_mask.data(), n_px * sizeof(uint8_t));

   int merge_regions = data->merge_regions;
   int iml = data->getImLoc(im);
   im = iml;
   if (iml == -1) throw std::runtime_error("Invalid dataset index");

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
            if (data->global_scope == Pixelwise)
            {
               param_data = alf.begin() + start * nl;

               int j = 0;
               for (int i = 0; i<n_px; i++)
                  if (im_mask[i] == rg || (merge_regions && im_mask[i] > rg))
                  {
                     model->getNonlinearOutputs(param_data + j*nl, buffer.begin());
                     image_data[i] = buffer[r_param];
                     j++;
                  }

            }
            else
            {
               param_data = alf.begin() + r_idx * nl;
               model->getNonlinearOutputs(param_data, buffer.begin());
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

            if (r_param < n_lin_output_params)
            {
               param_data = lin_params.begin() + start * lmax;

               int j = 0;
               for (int i = 0; i < n_px; i++)
                  if (im_mask[i] == rg || (merge_regions && im_mask[i] > rg))
                  {
                     model->getLinearOutputs(param_data + j * lmax, buffer.begin());
                     image_data[i] = buffer[r_param];
                     j++;
                  }


            }
            else
            {
               r_param -= n_lin_output_params;

               if (r_param < n_aux)
               {
                  param_data = aux_data.begin() + start * n_aux + r_param;
                  span = n_aux;
               } r_param -= n_aux;

               if (r_param == 0)
                  param_data = chi2.begin() + start;
               r_param -= 1;

               int j = 0;
               for (int i = 0; i < n_px; i++)
                  if (im_mask[i] == rg || (merge_regions && im_mask[i] > rg))
                     image_data[i] = param_data[span*(j++)];
            }
         }

      }
   }

   return 0;
}
