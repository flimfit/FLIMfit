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

#pragma once

#include "DecayModel.h"
#include "RegionStats.h"
#include <cstdint>

#include <vector>
#include <memory>
#include <cv.h>

using std::vector;
using std::string;

class FLIMData;
class FitResultsRegion;

class RegionSummary
{
public:
   int image;
   int region;
   int size;
   int iterations;
   float success;
};

class FitResults
{
public:
   FitResults(shared_ptr<DecayModel> model, shared_ptr<FLIMData> data, int calculate_errors);
   ~FitResults();

   const vector<string>& getOutputParamNames() { return param_names; };
   int getNumOutputRegions() { return n_regions; }
   int getNumOutputParams() { return n_output_params; }

   float* getAuxDataPtr(int image, int region);
   
   const FitResultsRegion getRegion(int image, int region);
   const FitResultsRegion getPixel(int image, int region, int pixel);
  
   void getNonLinearParams(int image, int region, int pixel, vector<double>& params);
   void getLinearParams(int image, int region, int pixel, vector<float>& params);

   void computeRegionStats(float confidence_factor);
   int getParameterImage(int im, int param, uint8_t ret_mask[], float image_data[]);

   vector<uint8_t>& getMask(int im) { return mask[im]; }
   
   int getNumX(int im);
   int getNumY(int im);
   
   const RegionStats<float> getStats() { return stats; }
   const vector<RegionSummary>& getRegionSummary() { return region_summary; }

private:

   vector<RegionSummary> region_summary;
   RegionStats<float> stats;
   
   void calculateMeanLifetime();
   void determineParamNames();

   int processLinearParams(float lin_params[], float lin_params_std[], float output_params[], float output_params_std[]);  
   
   void getPointers(int image, int region, int pixel, float*& non_linear_params, float*& linear_params, float*& chi2);
   void setFitStatus(int image, int region, int code);

   shared_ptr<FLIMData> data;
   shared_ptr<DecayModel> model;

   bool pixelwise;
   int n_px;
   int lmax;
   int nl;
   int n_meas;
   int n_im;
   int n_regions;

   int n_aux;

   vector<float> alf;
   vector<float> alf_err_lower;
   vector<float> alf_err_upper;
   vector<float> lin_params; 
   vector<float> chi2; 
   vector<float> aux_data;
   
   vector<int> ierr;
   vector<float> success; 
   vector<vector<uint8_t>> mask;


   int calculate_errors;
   
   int n_output_params;
   int n_nl_output_params;
   int n_lin_output_params;
   vector<const char*> param_names_ptr;
   vector<string> param_names;

   std::vector<cv::Size> image_size;

   friend class FitResultsRegion;
};

class FitResultsRegion
{
   friend class FitResults;

public:
   FitResultsRegion() : 
      results(0), image(0), region(0), pixel(0), is_pixel(false) {};

   FitResultsRegion(FitResults* results, int image, int region) : 
      results(results), image(image), region(region), pixel(0), is_pixel(false) {};

  FitResultsRegion(FitResults* results, int image, int region, int pixel) : 
      results(results), image(image), region(region), pixel(pixel), is_pixel(true) {};

  void getPointers(float*& non_linear_params, float*& linear_params, float*& chi2);
  void setFitStatus(int code);

private:
   FitResults* results;
   int image;
   int region;
   int pixel;
   bool is_pixel;
};