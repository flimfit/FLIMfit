#ifndef _FLIMDATA_
#define _FLIMDATA_

#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <boost/cstdint.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>

#include "FlagDefinitions.h"

#define MAX_REGION 255

#define MODE_PIXELWISE 0
#define MODE_IMAGEWISE 1
#define MODE_GLOBAL    2

#define BG_NONE 0
#define BG_VALUE 1
#define BG_IMAGE 2

using namespace boost;

class FLIMData
{

public:

   FLIMData(int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], int t_skip[], int n_t, int data_type,
            int* use_im, int mask[], int threshold, int limit, int global_mode, int smoothing_factor, int n_thread);

   void SetData(double data[]);
   void SetData(uint16_t data[]);
   int  SetData(char* data_file, int data_class, int data_skip);

   template <typename T>
   int CalculateRegions();

   int GetRegionData(int thread, int group, int region, double* adjust, double* region_data, double* mean_region_data);
   int GetPixelData(int thread, int im, int p, double* adjust, double* masked_data);
   
   
   int GetMaxRegion(int group);
   int GetMinRegion(int group);
   
   int GetMaskedData(int thread, int im, int region, double* adjust, double* masked_data);
   int GetRegionIndex(int group, int region);

   void SetExternalResampleIdx(int ext_n_meas_res, int* ext_resample_idx);
   int* GetResampleIdx(int thread);
   int GetResampleNumMeas(int thread);

   double* GetT();  

   void SetBackground(double* background_image);
   void SetBackground(double background);

   void ClearMapping();


   ~FLIMData();

   int n_im;
   int n_x;
   int n_y;
   int n_t;

   int n_chan;
   int n_meas;

   int n_group; 
   int n_px; 

   int n_regions_total;
   int max_region_size;
   int data_type;

   int data_skip;

   int* mask;

   int* region_start;

   int global_mode;

   int smoothing_factor;

   int* t_skip;

   double* t;

private:

   void DetermineAutoSampling(int thread, double decay[]);

   template <typename T>
   T* GetDataPointer(int thread, int im);

   template <typename T>
   void TransformImage(int thread, int im);

   void* data;

   double* tr_data;
   double* tr_buf;

   boost::interprocess::file_mapping data_map_file;
   boost::interprocess::mapped_region* data_map_view;

   char *data_file; 

   int *min_region;
   int *max_region;

   int data_mode;
   
   int has_data;
   int supplied_mask;

   int background_type;
   int background_value;
   double* background_image;

   int n_thread;

   int n_p;
   int n_meas_full;

   int n_t_full;

   int threshold;
   int limit;

   int* cur_transformed;

   double* average_data;

   int data_class;

   int* resample_idx;
   //int* n_t_res;
   int* n_meas_res;

   bool use_ext_resample_idx;
   int* ext_resample_idx;
   int ext_n_meas_res;

   int* use_im;
   int n_im_used;
};


template <typename T>
T* FLIMData::GetDataPointer(int thread, int im)
{
   using namespace boost::interprocess;

   if (use_im != NULL)
      im = use_im[im];
   std::size_t offset, buf_size;

   int im_size = n_t_full * n_chan * n_x * n_y;

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

   int* r_count = new int[MAX_REGION];
   int average_count = 0;
   int n_ipx = n_x*n_y;

   n_regions_total = 0;

   for(int j=0; j<n_meas_full; j++)
      average_data[j] = 0;

   for(int i=0; i<n_im_used; i++)
   {
      T* data_ptr = GetDataPointer<T>(0, i);

      if (data_ptr == NULL)
      {
         delete[] r_count;
         return ERR_FAILED_TO_MAP_DATA;
      }
      
      //#pragma omp parallel for
      for(int p=0; p<n_ipx; p++)
      {
         T* ptr = data_ptr + p*n_meas_full;
         double intensity = 0;
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

         if (mask[i*n_ipx+p])
         {
            for(int j=0; j<n_meas_full; j++)
               average_data[j] += data_ptr[p*n_meas_full+j];
            average_count++;
         }
       }
   }

   for(int j=0; j<n_meas_full; j++)
      average_data[j] /= average_count;

   for(int j=0; j<n_thread; j++)
      DetermineAutoSampling(j,average_data+t_skip[0]);

   region_start[0] = 0;

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
      memset(r_count, 0, MAX_REGION*sizeof(int));
      max_region_size = 0;
      
      for(int i=0; i<n_im; i++)
      {
         int im = i;
         if (use_im != NULL)
            im = use_im[im];
         
         for(int p=0; p<n_ipx; p++)
            r_count[mask[im*n_ipx+p]]++;
      }

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

   return 0;

}


template <typename T>
void FLIMData::TransformImage(int thread, int im)
{
   int idx, tr_idx;

   T* data_ptr = GetDataPointer<T>(thread, im);

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
               for(int i=0; i<n_t; i++)
                  tr_ptr[i] = data_ptr[t_skip[c]+i];
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



#endif
