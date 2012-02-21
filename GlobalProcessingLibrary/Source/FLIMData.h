#ifndef _FLIMDATA_
#define _FLIMDATA_

#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>

#include "FlagDefinitions.h"

#define MAX_REGION 255

#define MODE_PIXELWISE 0
#define MODE_IMAGEWISE 1
#define MODE_GLOBAL    2

#define BG_NONE 0
#define BG_VALUE 1
#define BG_IMAGE 2

//using namespace boost::interprocess;

class FLIMData
{

public:

   FLIMData(int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], int t_skip[], int n_t, int data_type,
            int mask[], int threshold, int limit, int global_mode, int smoothing_factor, int n_thread);

   void SetData(double data[]);
   int  SetData(char* data_file);

   void CalculateRegions();

   int GetRegionData(int thread, int group, int region, double* adjust, double* region_data, double* mean_region_data);
   int GetPixelData(int thread, int im, int p, double* adjust, double* masked_data);
   
   
   int GetMaxRegion(int group);
   int GetMinRegion(int group);
   
   int GetMaskedData(int thread, int im, int region, double* adjust, double* masked_data);
   int GetRegionIndex(int group, int region);

   double* FLIMData::GetT();  

   double* GetDataPointer(int thread, int im);

   void TransformImage(int thread, int im);

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

   int* mask;

   int* region_start;

   int global_mode;

   int smoothing_factor;

   int* t_skip;

   double* t;

   int* resample_idx;

private:

   double* data;

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
};

#endif