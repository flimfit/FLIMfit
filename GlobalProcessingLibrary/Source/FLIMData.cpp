#include "FLIMData.h"
FLIMData::FLIMData(int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], int t_skip[], int n_t, int data_type, int mask[], 
                   int threshold, int limit, int global_mode, int smoothing_factor, int n_thread) :
   n_im(n_im), 
   n_x(n_x),
   n_y(n_y),
   n_chan(n_chan),
   n_t_full(n_t_full),
   t(t),
   n_t(n_t),
   data_type(data_type),
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


   if (global_mode == MODE_PIXELWISE)
   {
      n_group = n_im * n_x * n_y;
      n_px = 1;
   }
   else if (global_mode == MODE_IMAGEWISE)
   {
      n_group = n_im;
      n_px = n_x * n_y;
      n_thread = (n_thread > n_im) ? n_im : n_thread;
   }
   else
   {
      n_group = 1;
      n_px = n_im * n_x * n_y;
      n_thread = 1;
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

   min_region = new int[n_im];
   max_region = new int[n_im];

   cur_transformed = new int[n_thread];

   for (int i=0; i<n_thread; i++)
      cur_transformed[i] = -1;

   int dim_required = smoothing_factor*2 + 2;
   if (n_x < dim_required || n_y < dim_required)
      this->smoothing_factor = 0;

      /*
   resample_idx = new int[n_t];
   int i;
   for (i=0; i<0.5*n_t; i++)
   {
      resample_idx[i] = 1;
   }
   for(i=i; i<n_t; i++)
   {
      resample_idx[i] = (i%2==0) ? 1 : 0;
   }
   */

}


int FLIMData::SetData(char* data_file)
{

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

   CalculateRegions();

   return 0;

}

void FLIMData::SetData(double data[])
{
   this->data = data;
   data_mode = DATA_DIRECT;
   
   CalculateRegions();
   
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

void FLIMData::CalculateRegions()
{

   int* r_count = new int[MAX_REGION];

   int n_ipx = n_x*n_y;

   n_regions_total = 0;

   for(int i=0; i<n_im; i++)
   {
      double* data_ptr = GetDataPointer(0, i);
      
      #pragma omp parallel for
      for(int p=0; p<n_ipx; p++)
      {
         double* ptr = data_ptr + p*n_meas_full;
         int intensity = 0;
         for(int j=0; j<n_meas_full; j++)
         {
            if (*ptr > limit)
            {
               mask[i*n_ipx+p] = 0;
               break;
            }
            intensity += *ptr;
            ptr++;
         }
         if (background_type == BG_VALUE)
            intensity -= background_value * n_meas_full;
         if (background_type == BG_IMAGE)
            intensity -= background_image[p] * n_meas_full;
         if (intensity < threshold)
            mask[i*n_ipx+p] = 0;
       }
   }

   region_start[0] = 0;

   if (global_mode == MODE_PIXELWISE)
   {
      max_region_size = 1;
      n_regions_total = n_im*n_x*n_y;
   }
   else if (global_mode == MODE_IMAGEWISE)
   {
      max_region_size = 0;
      for(int i=0; i<n_im; i++)
      {

         if (i>0)
            region_start[i] = region_start[i-1] + max_region[i-1] - min_region[i-1] + 1;

         memset(r_count, 0, MAX_REGION*sizeof(int));

         for(int p=0; p<n_ipx; p++)
            r_count[mask[i*n_ipx+p]]++;

         max_region[i] = 0;
         min_region[i] = 1;

         int j;
         for(j=1; j<MAX_REGION; j++)
         {
            if (r_count[j]>0)
            {
               min_region[i] = j;
               break;
            }
         }
         for(j=j; j<MAX_REGION; j++)
         {
            if (r_count[j]>0)
               max_region[i] = j;
            if (r_count[j]>max_region_size)
               max_region_size = r_count[j];
         }

         n_regions_total += max_region[i] - min_region[i] + 1;
            
      }
   }
   else
   {
      memset(r_count, 0, MAX_REGION*sizeof(int));
      max_region_size = 0;
      
      for(int i=0; i<n_im; i++)
         for(int p=0; p<n_p; p++)
            r_count[mask[i*n_ipx+p]]++;

      max_region[0] = 0;
      min_region[0] = 1;

      int j;
      for(j=1; j<=MAX_REGION; j++)
      {
         if (r_count[j]>0)
         {
            min_region[0] = j;
            break;
         }
      }
      for(j=j; j<=MAX_REGION; j++)
      {
         if (r_count[j]>0)
            max_region[0] = j;
         if (r_count[j]>max_region_size)
            max_region_size = r_count[j];
      }

      n_regions_total += max_region[0] - min_region[0] + 1;
 
   }

   delete[] r_count;

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

   if ( global_mode == MODE_PIXELWISE )
   {
      int im = group / (n_x*n_y);
      int p = group - im*n_x*n_y;

      if (im != cur_transformed[thread])
         TransformImage(thread, im);

      s = GetPixelData(thread, im, p, adjust, region_data);
   }
   else if ( global_mode == MODE_IMAGEWISE )
   {
      TransformImage(thread, group);
      s = GetMaskedData(thread, group, region, adjust, region_data);
   }
   else
   {
      s = 0;
      for(int i=0; i<n_im; i++)
      {
         TransformImage(thread, i);
         s += GetMaskedData(thread, group, region, adjust, region_data + s);
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

   int s = 0;
   if (mask[im*n_x*n_y+p])
   {
      for(int j=0; j<n_meas; j++)
         masked_data[j] = tr_data[p*n_meas + j] - adjust[j];
      s = 1;  
   }

   return s;
}

int FLIMData::GetMaskedData(int thread, int im, int region, double* adjust, double* masked_data)
{

   int* im_mask = mask + im*n_x*n_y;
   double* tr_data = this->tr_data + thread * n_p;
 
   // Store masked values
   int s = 0;
   for(int i=0; i<n_x*n_y; i++)
   {
      if (im_mask[i] == region)
      {
         for(int j=0; j<n_meas; j++)
            masked_data[s*n_meas+j] = tr_data[i*n_meas + j] - adjust[j];
         s++;
      }
   }

   return s;
}

void FLIMData::TransformImage(int thread, int im)
{
   int idx, tr_idx;

   double* data_ptr = GetDataPointer(thread, im);

   double* tr_data = this->tr_data + thread * n_p;
   double* tr_buf  = this->tr_buf  + thread * n_x;

   if ( smoothing_factor == 0 )
   {
      double* tr_ptr = tr_data;

      // Copy data from source to tr_data, skipping cropped time points
      for(int y=0; y<n_y; y++)
         for(int x=0; x<n_x; x++)
            for(int c=0; c<n_chan; c++)
            {
               memcpy(tr_ptr, data_ptr+t_skip[c], n_t*sizeof(double));
               data_ptr += n_t_full;
               tr_ptr += n_t;
            }
   }
   else
   {
      int s = smoothing_factor;

      int dxt = n_meas; 
      int dyt = n_x * dxt; 

      int dx = n_t_full * n_chan;
      int dy = n_x * dx; 

      for(int c=0; c<n_chan; c++)
         for(int i=0; i<n_t; i++)
         {
            tr_idx = c*n_t + i;
            idx = c*n_t_full + t_skip[c] + i;

            //Smooth in y axis
            for(int x=0; x<n_x; x++)
            {
               for(int y=0; y<s; y++)
               {
                  tr_data[y*dyt+x*dxt+tr_idx] = 0;
                  for(int yp=0; yp<y+s; yp++)
                     tr_data[y*dyt+x*dxt+tr_idx] += data_ptr[yp*dy+x*dx+idx];
                  tr_data[y*dyt+x*dxt+tr_idx] /= y+s;
               }

               for(int y=s; y<n_y-s; y++ )
               {
                  tr_data[y*dyt+x*dxt+tr_idx] = 0;
                  for(int yp=y-s; yp<=y+s; yp++)
                     tr_data[y*dyt+x*dxt+tr_idx] += data_ptr[yp*dy+x*dx+idx];
                  tr_data[y*dyt+x*dxt+tr_idx] /= 2*s+1;
               }

               for(int y=n_y-s; y<n_y; y++ )
               {
                  tr_data[y*dyt+x*dxt+tr_idx] = 0;
                  for(int yp=y-s; yp<n_y; yp++)
                     tr_data[y*dyt+x*dxt+tr_idx] += data_ptr[yp*dy+x*dx+idx];
                  tr_data[y*dyt+x*dxt+tr_idx] /= n_y-(y-s);
               }
            }

            //Smooth in x axis
            for(int y=0; y<n_y; y++)
            {
               for(int x=0; x<s; x++)
               {
                  tr_buf[x] = 0;
                  for(int xp=0; xp<x+s; xp++)
                     tr_buf[x] += tr_data[y*dyt+xp*dxt+tr_idx];
                  tr_buf[x] /= x+s;
               }

               for(int x=s; x<n_x-s; x++)
               {
                  tr_buf[x] = 0;
                  for(int xp=x-s; xp<=x+s; xp++)
                     tr_buf[x] += tr_data[y*dyt+xp*dxt+tr_idx];
                  tr_buf[x] /= 2*s+1;
               }

               for(int x=n_x-s; x<n_x; x++ )
               {
                  tr_buf[x] = 0;
                  for(int xp=x-s; xp<n_x; xp++)
                     tr_buf[x] += tr_data[y*dyt+xp*dxt+tr_idx];
                  tr_buf[x] /= n_x-(x-s);
               }

               for(int x=0; x<n_x; x++)
                  tr_data[y*dyt+x*dxt+tr_idx] = tr_buf[x];

            }

         }
   }


   // Subtract background
   if (background_type == BG_VALUE)
   {
      int n_tot = n_x * n_y * n_chan * n_t;
      for(int i=0; i<n_tot; i++)
         tr_data[i] -= background_value;
   }
   else if (background_type == BG_IMAGE)
   {
      int n_px = n_x * n_y;
      for(int p=0; p<n_px; p++)
         for(int i=0; i<n_meas; i++)
            tr_data[p*n_meas+i] -= background_image[p];
   }

   cur_transformed[thread] = im;

}


double* FLIMData::GetDataPointer(int thread, int im)
{
   using namespace boost::interprocess;

   std::size_t offset, buf_size;

   int im_size = n_t_full * n_chan * n_x * n_y;

   double *data_ptr;

   try
   {
      if (data_mode == DATA_MAPPED)
      {
         buf_size = im_size * sizeof(double);
         offset   = im * im_size * sizeof(double);
         
         data_map_view[thread] = mapped_region(data_map_file, read_only, offset, buf_size);
         data_ptr = (double*) data_map_view[thread].get_address();
      }
      else
      {
         data_ptr = this->data + im * im_size;
      }
   }
   catch(std::exception& e)
   {
      e = e;
      data_ptr = NULL;
   }

   return data_ptr;
}


void FLIMData::ClearMapping()
{
   for(int i=0; i<n_thread; i++)
      data_map_view[i] = boost::interprocess::mapped_region();
}


FLIMData::~FLIMData()
{
   delete[] tr_data;
   delete[] tr_buf;
   delete[] cur_transformed;

   delete[] data_map_view;

   if (!supplied_mask) 
      delete[] mask;

   delete[] max_region;
   delete[] min_region;
   delete[] t_skip;

   //delete[] resample_idx;
}