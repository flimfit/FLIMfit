#ifndef _FLIMDATA_
#define _FLIMDATA_

#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <stdint.h>
#include <boost/bind.hpp>
#include <boost/function.hpp>

#include "FlagDefinitions.h"

#define MAX_REGION 255

using namespace boost;

class FLIMData
{

public:

   FLIMData(int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], double t_int[], int t_skip[], int n_t, int data_type,
            int* use_im, uint8_t mask[], int threshold, int limit, double counts_per_photon, int global_mode, int smoothing_factor, int use_autosampling, int n_thread);

   int  SetData(float data[]);
   int  SetData(uint16_t data[]);
   int  SetData(char* data_file, int data_class, int data_skip);

   template <typename T>
   int CalculateRegions();

   int GetRegionData(int thread, int group, int region, int px, float* adjust, float* region_data, float* intensity_data, float* weight, int* irf_idx, float* local_decay);
   void DetermineAutoSampling(int thread, float decay[], int n_min_bin);

//   int GetPixelData(int thread, int im, int p, int n_min_bin, float* adjust, float* masked_data, float* local_decay);

//   int GetMaxRegion(int group);
//   int GetMinRegion(int group);

   int GetRegionIndex(int im, int region);
   int GetRegionPos(int im, int region);
   int GetRegionCount(int im, int region);

   int GetMaskedData(int thread, int im, int region, float* adjust, float* masked_data, float* masked_intensity, int* irf_idx);
   
   int GetImLoc(int im);

   void SetExternalResampleIdx(int ext_n_meas_res, int* ext_resample_idx);
   int* GetResampleIdx(int thread);
   int GetResampleNumMeas(int thread);

   double* GetT();  

   void SetBackground(float* background_image);
   void SetBackground(float background);

   void ClearMapping();


   ~FLIMData();

   int n_im;
   int n_x;
   int n_y;
   int n_t;
   int n_buf;

   int n_chan;
   int n_meas;

   int n_px;
   int n_p;

   int n_regions_total;
   int max_region_size;
   int data_type;

   int data_skip;

   int use_autosampling;

   uint8_t* mask;
   int n_masked_px;


   int global_mode;

   int smoothing_factor;
   double smoothing_area;

   int* t_skip;

   double* t;
   double* t_int;

   double counts_per_photon;

   int* use_im;
   int n_im_used;


private:


   template <typename T>
   T* GetDataPointer(int thread, int im);

   template <typename T>
   void TransformImage(int thread, int im);

   void* data;

   float* tr_data;
   float* tr_buf;
   float* tr_row_buf;
   float* intensity;

   boost::interprocess::file_mapping data_map_file;
   boost::interprocess::mapped_region* data_map_view;

   int* region_idx;
   int* region_count;
   int* region_pos;


   char *data_file; 

   int *min_region;
   int *max_region;

   int data_mode;
   
   int has_data;
   int supplied_mask;

   int background_type;
   float background_value;
   float* background_image;

   int n_thread;

   int n_meas_full;

   int n_t_full;

   int threshold;
   int limit;

   int* cur_transformed;

   float* average_data;

   int data_class;

   int* resample_idx;
   int* n_meas_res;

   bool use_ext_resample_idx;
   int* ext_resample_idx;
   int ext_n_meas_res;



   float* mean_image;


};


template <typename T>
T* FLIMData::GetDataPointer(int thread, int im)
{
   using namespace boost::interprocess;

   if (use_im != NULL)
      im = use_im[im];
   unsigned long long offset, buf_size;

   unsigned long long int im_size = n_t_full * n_chan * n_x * n_y;

   int data_size = sizeof(T);

   T* data_ptr;

   try
   {
      if (data_mode == DATA_MAPPED)
      {
         buf_size = im_size * data_size;
         offset   = im * im_size * data_size + data_skip;

         data_map_view[thread] = mapped_region(data_map_file, read_only, offset, buf_size);
         data_ptr = (T*) data_map_view[thread].get_address();
      }
      else 
      {
         data_ptr = ((T*)data) + im * im_size;
      }
   }
   catch(std::exception& e)
   {
      e = e;
      data_ptr = NULL;
   }

   return data_ptr;
}



template <typename T>
int FLIMData::CalculateRegions()
{
   int cur_pos;
   int average_count = 0;
   int n_ipx = n_x*n_y;

   n_regions_total = 0;

   int r_count, r_idx; 
   
   T* cur_data = new T[ n_ipx * n_meas_full ];

   for(int i=0; i<n_im_used; i++)
   {
      T* data_ptr = GetDataPointer<T>(0, i);

      int im = i;
      if (use_im != NULL)
            im = use_im[im];

      if (data_ptr == NULL)
      {
         delete[] cur_data;
         return ERR_FAILED_TO_MAP_DATA;
      }

      memcpy(cur_data,data_ptr, n_ipx * n_meas_full * sizeof(T));
      
      // We already have segmentation mask, now calculate integrated intensity
      // and apply min intensity and max bin mask
      //----------------------------------------------------

      //#pragma omp parallel for
      for(int p=0; p<n_ipx; p++)
      {
         //T* ptr = data_ptr + p*n_meas_full;
         T* ptr = cur_data + p*n_meas_full;
         double intensity = 0;
         for(int k=0; k<n_chan; k++)
         {
            for(int j=0; j<n_t_full; j++)
            {
               if (limit > 0 && *ptr >= limit)
               {
                  mask[im*n_ipx+p] = 0;
                  break;
               }
               intensity += *ptr;
               ptr++;
            }
         }
         if (background_type == BG_VALUE)
            intensity -= background_value * n_meas_full;
         if (background_type == BG_IMAGE)
            intensity -= background_image[p] * n_meas_full;

         if (intensity < threshold)
            mask[im*n_ipx+p] = 0;

         n_masked_px += (mask[im*n_ipx+p] > 0);
       }
   }

   // Determine how many regions we have in each image
   //--------------------------------------------------------
   for(int i=0; i<n_im_used; i++)
   {
      int im = i;
      if (use_im != NULL)
         im = use_im[im];
         
      memset(region_count + i * MAX_REGION, 0, MAX_REGION*sizeof(int));

      for(int p=0; p<n_ipx; p++)
      {
         int idx = mask[im*n_ipx+p];
         region_count[idx + i * MAX_REGION]++;
      }
   }


   if (global_mode == MODE_PIXELWISE || global_mode == MODE_IMAGEWISE)
   {
      r_idx = 0;
      cur_pos = 0;

      for(int i=0; i<n_im_used; i++)
      {
         for(int j=1; j<MAX_REGION; j++)
         {
            region_pos[ i* MAX_REGION + j ] = cur_pos;
            cur_pos += region_count[ i* MAX_REGION + j ];
            if (region_count[ i* MAX_REGION + j ] > 0)
               region_idx[ i* MAX_REGION + j ] = r_idx++;
         }
      }
   }
   else
   {
      cur_pos = 0;
      r_idx = 0;

      for(int j=1; j<MAX_REGION; j++)
      {
         r_count = 0;
         for(int i=0; i<n_im_used; i++)
         {
            region_pos[ j + i* MAX_REGION ] = cur_pos;
            cur_pos += region_count[ j + i * MAX_REGION ];
            r_count += region_count[ j + i * MAX_REGION ];
         }

         if (r_count > 0)
            for(int i=0; i<n_im_used; i++)
               region_idx[ j + i * MAX_REGION ] = r_idx++;
      }
   }
   
   n_regions_total = r_idx;

   /*
   if (global_mode == MODE_PIXELWISE)
   {
      max_region_size = 1;
      n_regions_total = n_im_used*n_x*n_y;
   }
   else if (global_mode == MODE_IMAGEWISE)
   {
      max_region_size = 0;
      for(int i=0; i<n_im_used; i++)
      {
         int im = i;
         if (use_im != NULL)
            im = use_im[im];

         if (i>0)
            region_start[i] = region_start[i-1] + max_region[i-1] - min_region[i-1] + 1;

         memset(r_count, 0, MAX_REGION*sizeof(int));

         for(int p=0; p<n_ipx; p++)
            r_count[mask[im*n_ipx+p]]++;

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
   */

//   delete[] r_count;
   delete[] cur_data;

   return 0;

}


template <typename T>
void FLIMData::TransformImage(int thread, int im)
{
   int idx, tr_idx;

   if (im == cur_transformed[thread])
      return;

   float* tr_data    = this->tr_data + thread * n_p;
   float* tr_buf     = this->tr_buf  + thread * n_p;
   float* intensity  = this->intensity + thread * n_px;
   float* tr_row_buf = this->tr_row_buf + thread * (n_x + n_y);
   float* mean_image = this->mean_image + thread * n_meas;

   T* data_ptr = GetDataPointer<T>(thread, im);
   memcpy(tr_buf, data_ptr, n_p * sizeof(T));


   double photons_per_count = 1/counts_per_photon;

   if ( smoothing_factor == 0 )
   {
      float* tr_ptr = tr_data;
      float* cur_data_ptr = tr_buf;
      // Copy data from source to tr_data, skipping cropped time points
      for(int y=0; y<n_y; y++)
         for(int x=0; x<n_x; x++)
            for(int c=0; c<n_chan; c++)
            {
               for(int i=0; i<n_t; i++)
                  tr_ptr[i] = cur_data_ptr[t_skip[c]+i];
               cur_data_ptr += n_t_full;
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

            /*
            for(int y=0; y<n_y; y++)
               for(int x=0; x<n_x; x++)
                  tr_buf[y*n_x+x] = data_ptr[yp*dy+x*dx+idx];
                  */

            //Smooth in y axis
            for(int x=0; x<n_x; x++)
            {
               for(int y=0; y<s; y++)
               {
                  tr_row_buf[y] = 0;
                  for(int yp=0; yp<y+s; yp++)
                     tr_row_buf[y] += tr_buf[yp*dy+x*dx+idx];
                  tr_row_buf[y] /= y+s;
               }

               //#pragma omp parallel for
               for(int y=s; y<n_y-s; y++ )
               {
                  tr_row_buf[y] = 0;
                  for(int yp=y-s; yp<=y+s; yp++)
                     tr_row_buf[y] += tr_buf[yp*dy+x*dx+idx];
                  tr_row_buf[y] /= 2*s+1;
               }

               for(int y=n_y-s; y<n_y; y++ )
               {
                  tr_row_buf[y] = 0;
                  for(int yp=y-s; yp<n_y; yp++)
                     tr_row_buf[y] += tr_buf[yp*dy+x*dx+idx];
                  tr_row_buf[y] /= n_y-(y-s);
               }

               for(int y=0; y<n_y; y++)
                  intensity[y*n_x+x] = tr_row_buf[y];
            }

            //Smooth in x axis
            for(int y=0; y<n_y; y++)
            {
               for(int x=0; x<s; x++)
               {
                  tr_row_buf[x] = 0;
                  for(int xp=0; xp<x+s; xp++)
                     tr_row_buf[x] += intensity[y*n_x+xp];
                  tr_row_buf[x] /= x+s;
               }

               for(int x=s; x<n_x-s; x++)
               {
                  tr_row_buf[x] = 0;
                  for(int xp=x-s; xp<=x+s; xp++)
                     tr_row_buf[x] += intensity[y*n_x+xp];
                  tr_row_buf[x] /= 2*s+1;
               }

               //#pragma omp parallel for
               for(int x=n_x-s; x<n_x; x++ )
               {
                  tr_row_buf[x] = 0;
                  for(int xp=x-s; xp<n_x; xp++)
                     tr_row_buf[x] += intensity[y*n_x+xp];
                  tr_row_buf[x] /= n_x-(x-s);
               }

               for(int x=0; x<n_x; x++)
                  tr_data[y*dyt+x*dxt+tr_idx] = tr_row_buf[x];

            }

         }
   }


   // Calculate intensity
   float* intensity_ptr = intensity;
   float* cur_data_ptr = tr_buf;
   for(int y=0; y<n_y; y++)
      for(int x=0; x<n_x; x++)
      {
         *intensity_ptr = 0;
         for(int i=0; i<n_t_full; i++)
         {
            *intensity_ptr += cur_data_ptr[i];
         }
         cur_data_ptr += n_t_full;
         intensity_ptr++;
      }




   // Subtract background
   if (background_type == BG_VALUE)
   {
      int n_tot = n_x * n_y * n_chan * n_t;
      for(int i=0; i<n_tot; i++)
      {
         tr_data[i] -= background_value;
         tr_data[i] *= photons_per_count;
      }
   }
   else if (background_type == BG_IMAGE)
   {
      int n_px = n_x * n_y;
      //#pragma omp parallel for
      for(int p=0; p<n_px; p++)
         for(int i=0; i<n_meas; i++)
         {
            tr_data[p*n_meas+i] -= background_image[p];
            tr_data[p*n_meas+i] *= photons_per_count;
         }
   } 
   else
   {
      int n_tot = n_x * n_y * n_chan * n_t;
      for(int i=0; i<n_tot; i++)
      {
         tr_data[i] *= photons_per_count;
      }
   }

   cur_transformed[thread] = im;

}



#endif
