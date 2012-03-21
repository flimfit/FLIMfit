#include "FLIMData.h"

FLIMData::FLIMData(int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], int t_skip[], int n_t, int data_type, 
                   int* use_im, int mask[], int threshold, int limit, int global_mode, int smoothing_factor, int n_thread) :
   n_im(n_im), 
   n_x(n_x),
   n_y(n_y),
   n_chan(n_chan),
   n_t_full(n_t_full),
   t(t),
   n_t(n_t),
   data_type(data_type),
   use_im(use_im),
   mask(mask),
   threshold(threshold),
   limit(limit),
   global_mode(global_mode),
   smoothing_factor(smoothing_factor)
{
   has_data = false;

   

   if (mask == NULL)
   {
      this->mask = new int[n_im * n_x * n_y];
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

   if (global_mode == MODE_PIXELWISE)
   {
      n_group = n_im_used * n_x * n_y;
      n_px = 1;
   }
   else if (global_mode == MODE_IMAGEWISE)
   {
      n_group = n_im_used;
      n_px = n_x * n_y;
      n_thread = (n_thread > n_im_used) ? n_im_used : n_thread;
   }
   else
   {
      n_group = 1;
      n_px = n_im_used * n_x * n_y;
      n_thread = (n_thread > n_im_used) ? n_im_used : n_thread;
   }

   this->n_thread = n_thread;

   n_meas = n_chan * n_t;
   n_meas_full = n_chan * n_t_full;

   background_value = 0;
   background_type = BG_NONE;

   if (n_thread < 1)
      n_thread = 1;

   n_p = n_x * n_y * n_meas;

   this->t_skip = new int[n_chan];
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

   tr_data = new double[ n_thread * n_p ]; 
   tr_buf  = new double[ n_thread * n_x ];

   region_start = new int[ n_group ];

   data_map_view = new boost::interprocess::mapped_region[n_thread];

   min_region = new int[n_im_used];
   max_region = new int[n_im_used];

   cur_transformed = new int[n_thread];

   average_data = new double[n_meas_full];

   for (int i=0; i<n_thread; i++)
      cur_transformed[i] = -1;

   int dim_required = smoothing_factor*2 + 2;
   if (n_x < dim_required || n_y < dim_required)
      this->smoothing_factor = 0;

     
   resample_idx = new int[n_t * n_thread];
   n_meas_res = new int[n_thread];

   use_ext_resample_idx = 0;
   ext_resample_idx = NULL;
   ext_n_meas_res = 0;
   
   for(int j=0; j<n_thread; j++)
   {
      for(int i=0; i<n_t-1; i++)
      {
         resample_idx[j*n_t+i] = 1;
      }
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
   
   this->data_file = new char[ strlen(data_file) + 1 ];
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
   if (data_class == DATA_DOUBLE)
      err = CalculateRegions<double>();
   else
      err = CalculateRegions<uint16_t>();

   return err;

}

void FLIMData::SetData(double* data)
{
   this->data = (void*) data;
   data_mode = DATA_DIRECT;
   data_class = DATA_DOUBLE;
   
   CalculateRegions<double>();
   
   has_data = true;
}

void FLIMData::SetData(uint16_t* data)
{
   this->data = (void*) data;
   data_mode = DATA_DIRECT;
   data_class = DATA_UINT16;

   CalculateRegions<uint16_t>();
   
   has_data = true;
}


void FLIMData::SetBackground(double* background_image)
{
   this->background_image = background_image;
   this->background_type = BG_IMAGE;
}

void FLIMData::SetBackground(double background)
{
   this->background_value = background;
   this->background_type = BG_VALUE;
}

int FLIMData::GetRegionIndex(int group, int region)
{
   if (global_mode == MODE_PIXELWISE)
      return group;
   else
      return region_start[group]+region-1;
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

void FLIMData::DetermineAutoSampling(int thread, double decay[])
{
   if (n_t < 100 || n_chan > 1)
      return;

   int* resample_idx = this->resample_idx + n_t * thread;

   double min_bin = 20.0 / ((smoothing_factor+1)*(smoothing_factor+1));
   int max_w = 50;

   resample_idx[n_t-1] = 0;
   double c = decay[n_t-1];
   int w = 1;
   for (int i=n_t-2; i>=0; i--)
   {
      if ( c < min_bin && w < max_w )
      {
         c += decay[i];
         resample_idx[i] = 0;
         w++;
      }
      else
      {
         w = 1;
         c = decay[i];
         resample_idx[i] = 1;
      }
   }
   
   int n_t_res = 1;

   for(int i=0; i<n_t; i++)
      n_t_res += resample_idx[i];

   n_meas_res[thread] = n_t_res * n_chan;

}



int FLIMData::GetMaxRegion(int group)
{
   if (global_mode == MODE_PIXELWISE)
      return mask[group];
   else
      return max_region[group];
}

int FLIMData::GetMinRegion(int group)
{
   if (global_mode == MODE_PIXELWISE)
      if (mask[group] == 0)
         return 1;
      else
         return mask[group];
   else
      return min_region[group];
}


int FLIMData::GetRegionData(int thread, int group, int region, double* adjust, double* region_data, double* mean_region_data)
{
   int s = 0;
   
   boost::function<void(int)> transform_fcn;
   
   if (data_class == DATA_DOUBLE)
      transform_fcn = boost::bind(&FLIMData::TransformImage<double>, this, thread, _1);
   else
      transform_fcn = boost::bind(&FLIMData::TransformImage<uint16_t>, this, thread, _1);
   
   if ( global_mode == MODE_PIXELWISE )
   {
      int im = group / (n_x*n_y);
      int p = group - im*n_x*n_y;

      if (im != cur_transformed[thread])
         transform_fcn(im);

      s = GetPixelData(thread, im, p, adjust, region_data);
   }
   else if ( global_mode == MODE_IMAGEWISE )
   {
      transform_fcn(group);
      s = GetMaskedData(thread, group, region, adjust, region_data);
   }
   else
   {
      s = 0;
      for(int i=0; i<n_im_used; i++)
      {
         transform_fcn(i);
         s += GetMaskedData(thread, i, region, adjust, region_data + s*n_meas_res[thread]);
      }
   }
   
   if ( mean_region_data != NULL )
   {
      memset(mean_region_data,0, n_meas * sizeof(double));

      for(int i=0; i<s; i++)
         for(int j=0; j<n_meas; j++)
            mean_region_data[j] += region_data[i*n_meas + j];
      
      for(int j=0; j<n_meas; j++)
         mean_region_data[j] /= s;
   }

   return s;
}


int FLIMData::GetPixelData(int thread, int im, int p, double* adjust, double* masked_data)
{
   double* tr_data = this->tr_data + thread * n_p;
   int*    resample_idx = this->resample_idx + thread * n_t; 

   if (use_im != NULL)
      im = use_im[im];

   if (mask[im*n_x*n_y+p]==0)
   {
      return 0;
   }

   int s = 0;
   int idx = 0;
   for(int j=0; j<n_meas; j++)
      masked_data[j] = 0;

   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         masked_data[idx] += tr_data[p*n_meas + k*n_t + i] - adjust[k*n_t+i];
         idx ++;
      }
   }
   s = 1;  


   DetermineAutoSampling(thread,masked_data);

   idx = 0;
   for(int j=0; j<n_meas_res[thread]; j++)
      masked_data[j] = 0;

   for(int k=0; k<n_chan; k++)
   {
      for(int i=0; i<n_t; i++)
      {
         masked_data[idx] += tr_data[p*n_meas + k*n_t + i] - adjust[k*n_t+i];
         idx += resample_idx[i];
      }
   }
   
   return 1;
}

int FLIMData::GetMaskedData(int thread, int im, int region, double* adjust, double* masked_data)
{

   if (use_im != NULL)
      im = use_im[im];

   int* im_mask = mask + im*n_x*n_y;
   double* tr_data = this->tr_data + thread * n_p;
   int idx = 0;

   // Store masked values
   int s = 0;
   for(int p=0; p<n_x*n_y; p++)
   {
      if (im_mask[p] == region)
      {
         memset(masked_data+idx,0,n_meas_res[thread]*sizeof(double));
         for(int k=0; k<n_chan; k++)
         {
            for(int i=0; i<n_t; i++)
            {
               masked_data[idx] += tr_data[p*n_meas + k*n_t + i] - adjust[k*n_t+i];
               idx += resample_idx[i];
            }
            idx++;
         }
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
   delete[] tr_data;
   delete[] tr_buf;
   delete[] cur_transformed;
   delete[] resample_idx;
   delete[] data_map_view;
   delete[] average_data;
   delete[] n_meas_res;
 
   if (!supplied_mask) 
      delete[] mask;

   delete[] max_region;
   delete[] min_region;
   delete[] t_skip;
}



