#include "FLIMData.h"
#include <math.h>

FLIMData::FLIMData(int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], double t_int[], int t_skip[], int n_t, int data_type, 
                   int* use_im, uint8_t mask[], int threshold, int limit, double counts_per_photon, int global_mode, int smoothing_factor, int use_autosampling, int n_thread) :
   n_im(n_im), 
   n_x(n_x),
   n_y(n_y),
   n_chan(n_chan),
   n_t_full(n_t_full),
   t(t),
   t_int(t_int),
   n_t(n_t),
   data_type(data_type),
   use_im(use_im),
   mask(mask),
   threshold(threshold),
   limit(limit),
   counts_per_photon(counts_per_photon),
   global_mode(global_mode),
   smoothing_factor(smoothing_factor),
   use_autosampling(use_autosampling)
{
   has_data = false;

   data_file = NULL;

   n_masked_px = 0;

   // Make sure we exclude very dim pixels which 
   // can break the autosampling (we might end up with only one bin!)
   if (threshold < 3)
      threshold = 3;

   if (mask == NULL)
   {
      this->mask = new uint8_t[n_im * n_x * n_y]; //ok
      supplied_mask = false;
      for(int i=0; i<n_im * n_x * n_y; i++)
         this->mask[i] = 1;
   }
   else
   {  
      supplied_mask = true;
   }

   n_im_used = 0;
   if (use_im != NULL)
   {
      for(int i=0; i<n_im; i++)
      {
         if (use_im[i])
         {
            use_im[n_im_used] = i;
            n_im_used++;
         }
      }
   }
   else
   {
      n_im_used = n_im;
   }

   this->n_thread = n_thread;

   n_meas = n_chan * n_t;
   n_meas_full = n_chan * n_t_full;

   background_value = 0;
   background_type = BG_NONE;

   if (n_thread < 1)
      n_thread = 1;

   n_px = n_x * n_y;
   n_p = n_x * n_y * n_meas_full;

   this->t_skip = new int[n_chan]; //ok
   if (t_skip == NULL)
   {
      for(int i=0; i<n_chan; i++)
         this->t_skip[i] = 0;
   }
   else
   {
      for(int i=0; i<n_chan; i++)
         this->t_skip[i] = t_skip[i];
   }

   tr_data    = new float[ n_thread * n_p ]; //ok
   tr_buf     = new float[ n_thread * n_p ]; //ok
   intensity  = new float[ n_thread * n_px ];
   tr_row_buf = new float[ n_thread * (n_x+n_y) ]; //ok

   region_count = new int[ n_im_used * MAX_REGION ];
   region_pos   = new int[ n_im_used * MAX_REGION ];
   region_idx   = new int[ n_im_used * MAX_REGION ];

   for (int i=0; i<n_im_used * MAX_REGION; i++)
   {
      region_count[i] = 0;
      region_pos[i] = 0;
      region_idx[i] = -1;
   }

   data_map_view = new boost::interprocess::mapped_region[n_thread]; //ok

   min_region = new int[n_im_used]; //ok
   max_region = new int[n_im_used]; //ok

   mean_image = new float[ n_thread * n_meas ]; //ok

   cur_transformed = new int[n_thread]; //ok 

   //average_data = new float[n_meas_full];

   for (int i=0; i<n_thread; i++)
      cur_transformed[i] = -1;

   int dim_required = smoothing_factor*2 + 2;
   if (n_x < dim_required || n_y < dim_required)
      this->smoothing_factor = 0;

   smoothing_area = (2*this->smoothing_factor+1)*(2*this->smoothing_factor+1);

   resample_idx = new int[n_t * n_thread]; //ok
   n_meas_res = new int[n_thread]; //ok

   use_ext_resample_idx = 0;
   ext_resample_idx = NULL;
   ext_n_meas_res = 0;
   
   for(int j=0; j<n_thread; j++)
   {
      for(int i=0; i<n_t-1; i++)
         resample_idx[j*n_t+i] = 1;
      
      resample_idx[j*n_t+n_t-1] = 0;

      n_meas_res[j] = n_t * n_chan;
   }
}

int FLIMData::SetData(char* data_file, int data_class, int data_skip)
{

   this->data_skip = data_skip;
   this->data_class = data_class;

   has_data = false;

   data_mode = DATA_MAPPED;
   
   this->data_file = new char[ strlen(data_file) + 1 ]; //ok
   strcpy(this->data_file,data_file);

   try
   {
      data_map_file = boost::interprocess::file_mapping(data_file,boost::interprocess::read_only);
   }
   catch(std::exception& e)
   {
      e = e;
      return ERR_COULD_NOT_OPEN_MAPPED_FILE;
   }

   has_data = true;

   int err = 0;
   if (data_class == DATA_FLOAT)
      err = CalculateRegions<float>();
   else
      err = CalculateRegions<uint16_t>();

   return err;

}

int FLIMData::SetData(float* data)
{
   this->data = (void*) data;
   data_mode = DATA_DIRECT;
   data_class = DATA_FLOAT;
   
   int err = CalculateRegions<float>();
   
   has_data = true;

   return err;
}

int FLIMData::SetData(uint16_t* data)
{
   this->data = (void*) data;
   data_mode = DATA_DIRECT;
   data_class = DATA_UINT16;

   int err = CalculateRegions<uint16_t>();
   
   has_data = true;

   return err;
}


void FLIMData::SetBackground(float* background_image)
{
   this->background_image = background_image;
   this->background_type = BG_IMAGE;
}

void FLIMData::SetBackground(float background)
{
   this->background_value = background;
   this->background_type = BG_VALUE;
}

int FLIMData::GetRegionIndex(int im, int region)
{
   return region_idx[region + im * MAX_REGION];
}

int FLIMData::GetRegionPos(int im, int region)
{
   return region_pos[region + im * MAX_REGION];
}

int FLIMData::GetRegionCount(int im, int region)
{
   return region_count[region + im * MAX_REGION];
}

int FLIMData::GetImLoc(int im)
{
   for(int i=0; i<n_im_used; i++)
   {
      if (use_im[i] == im)
         return i;
   }
   return -1;
}

double* FLIMData::GetT()
{
   return t + t_skip[0];
}

void FLIMData::SetExternalResampleIdx(int ext_n_meas_res, int* ext_resample_idx)
{
   use_ext_resample_idx = true;
   this->ext_n_meas_res = ext_n_meas_res;
   this->ext_resample_idx = ext_resample_idx;
}


int* FLIMData::GetResampleIdx(int thread)
{
   if (use_ext_resample_idx)
      return ext_resample_idx;
   else
      return resample_idx + thread * n_t;
}

int FLIMData::GetResampleNumMeas(int thread)
{
   if (use_ext_resample_idx)
      return ext_n_meas_res;
   else
      return n_meas_res[thread];
}

void FLIMData::DetermineAutoSampling(int thread, float decay[], int n_bin_min)
{
   float buf;
   int idx;

   if (data_type != DATA_TYPE_TCSPC || n_chan > 1 || !use_autosampling || use_ext_resample_idx)
      return;

   int* resample_idx = this->resample_idx + n_t * thread;

   int   max_w = n_t / 5;
   float min_c = 20.0 / smoothing_area;
   
   int total_count = 0;
   
   int last = -1;
   for(int i=0; i<n_t; i++)
   {
      resample_idx[i] = 0;
      total_count += decay[i];
   }
      
   if (total_count < n_bin_min*min_c)
   {
      min_c = total_count / n_bin_min;
   }

   resample_idx[n_t-1] = 0;
   float c = decay[n_t-1];
   int w = 0;
   int n_bin = 1;
   for (int i=n_t-2; i>=0; i--)
   {
      if ( c < min_c && w < max_w )
      {
         c += decay[i];
         w++;
      }
      else
      {
         c = decay[i];
         resample_idx[i] = 1;
         last = i;
         w = 1;
         n_bin++;
      }
   }

   if ((c < min_c) && (n_bin > n_bin_min))
      resample_idx[last] = 0;

   n_meas_res[thread] = n_bin * n_chan;


   // Now resample data provided
   idx = 0;
   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         buf = decay[k*n_t + i];
         decay[k*n_t + i] = 0;
         decay[idx] += buf;
         idx += resample_idx[i];
      }
      idx++;
   }


}


/*
int FLIMData::GetMaxRegion(int group)
{
   if (global_mode == MODE_PIXELWISE)
   {
      int im = group / (n_x*n_y);
      int px = group % (n_x*n_y);

      if (use_im != NULL)
         im = use_im[im];
#
      return mask[im*n_x*n_y+px];
   }
   else
   {
      return max_region[group];
   }
}

int FLIMData::GetMinRegion(int group)
{
   if (global_mode == MODE_PIXELWISE)
   {
      int im = group / (n_x*n_y);
      int px = group % (n_x*n_y);

      if (use_im != NULL)
         im = use_im[im];

      int m = mask[im*n_x*n_y+px];
            
      return (m==0) ? 1 : m;
   }
   else
   {
      return min_region[group];
   }
}
*/

int FLIMData::GetRegionData(int thread, int group, int region, int px, float* adjust, float* region_data, float* intensity_data, float* weight, int* irf_idx, float* local_decay)
{
   int s = 0;

   if ( global_mode == MODE_PIXELWISE )
   {
      s = 1;
      region_data = region_data + px * n_meas;
   }
   if ( global_mode == MODE_IMAGEWISE )
   {
      s = GetMaskedData(thread, group, region, adjust, region_data, intensity_data, irf_idx);
   }
   else if ( global_mode == MODE_GLOBAL )
   {
      s = 0;
      for(int i=0; i<n_im_used; i++)
      {
         s += GetMaskedData(thread, i, region, adjust, region_data + s*GetResampleNumMeas(thread), intensity_data + s, irf_idx + s);
      }
   }
   
   memset(weight,0, n_meas * sizeof(*weight));

   for(int i=0; i<s; i++)
      for(int j=0; j<n_meas; j++)
         weight[j] += region_data[i*n_meas + j];
      
   for(int j=0; j<n_meas; j++)
      weight[j] /= s;

   for(int j=0; j<n_meas; j++)
      local_decay[j] = weight[j];

   for(int j=0; j<n_meas; j++)
   {
      weight[j] += adjust[j];
      if (weight[j] <= 0)
         weight[j] = 1;   // If we have a zero data point set to 1
      else
         weight[j] = 1/sqrt(weight[j]);
   }

   return s;
}


int FLIMData::GetMaskedData(int thread, int im, int region, float* adjust, float* masked_data, float* masked_intensity, int* irf_idx)
{
   
   int iml = im;
   if (use_im != NULL)
      iml = use_im[im];

   uint8_t* im_mask = mask + iml*n_x*n_y;
   float*   tr_data = this->tr_data + thread * n_p;
   int*     resample_idx = GetResampleIdx(thread);

   int idx = 0;
   int int_idx = 0;

   if (data_class == DATA_FLOAT)
      TransformImage<float>(thread, im);
   else
      TransformImage<uint16_t>(thread, im);

   // Store masked values
   int s = 0;
   for(int p=0; p<n_px; p++)
   {
      if (region < 0 || im_mask[p] == region)
      {
         masked_intensity[int_idx] = intensity[p];
         memset(masked_data+idx,0,sizeof(*masked_data)*GetResampleNumMeas(thread));
         for(int k=0; k<n_chan; k++)
         {
            for(int i=0; i<n_t; i++)
            {
               masked_data[idx] += tr_data[p*n_meas + k*n_t + i] - adjust[k*n_t+i];
               idx += resample_idx[i];
            }
            idx++;
         }
         int_idx++;
         irf_idx[s] = p;
         s++;
      }
   }

   return s;
}



void FLIMData::ClearMapping()
{
   if (data_map_view == NULL)
      return;
   for(int i=0; i<n_thread; i++)
      data_map_view[i] = boost::interprocess::mapped_region();
}



FLIMData::~FLIMData()
{
   ClearMapping();

   delete[] tr_data;
   delete[] tr_buf;
   delete[] tr_row_buf;
   delete[] intensity;
   delete[] cur_transformed;
   delete[] resample_idx;
   delete[] data_map_view;
   delete[] n_meas_res;
 
   if (!supplied_mask) 
      delete[] mask;

   delete[] max_region;
   delete[] min_region;
   delete[] t_skip;
   delete[] mean_image;
   delete[] region_count;

   if (data_file != NULL)
      delete[] data_file;
}



