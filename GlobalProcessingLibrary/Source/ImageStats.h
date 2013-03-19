//=========================================================================
//  
//  ImageStats.h
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//  Provides convenience class for handling image statistics
//
//=========================================================================

#ifndef IMAGE_STATS_H
#define IMAGE_STATS_H

enum PARAM_IDX { PARAM_MEAN, PARAM_W_MEAN, PARAM_STD, PARAM_W_STD, PARAM_MEDIAN, 
                 PARAM_Q1, PARAM_Q2, PARAM_01, PARAM_99, PARAM_ERR_LOWER, PARAM_ERR_UPPER };

const int N_STATS = 11;

/**
 * Convenience class to encapsulate returned results for a dataset
 */

template<typename T>
class ImageStats
{
public:

   ImageStats(T* params)
   {
      this->params = params;
      next_param = params;
      idx = 0;
   };


   /**
    * Set the next parameter statistics to specified values
    */ 
   void SetNextParam(T mean, T w_mean, T std, T w_std, T median, T q1, T q2, T p01, T p99, T err_lower, T err_upper )
   {

      next_param[PARAM_MEAN] = mean; 
      next_param[PARAM_W_MEAN] = w_mean; 
      next_param[PARAM_STD] = std; 
      next_param[PARAM_W_STD] = w_std; 
      next_param[PARAM_MEDIAN] = median; 
      next_param[PARAM_Q1] = q1; 
      next_param[PARAM_Q2] = q2; 
      next_param[PARAM_01] = p01; 
      next_param[PARAM_99] = p99; 

      next_param[PARAM_ERR_LOWER] = err_lower;
      next_param[PARAM_ERR_UPPER] = err_upper;

      next_param += N_STATS;

      idx++;
   }

   /**
    * Set the next parameter to @mean, parameter has no variance 
    */
   void SetNextParam(T mean)
   {

      next_param[PARAM_MEAN] = mean; 
      next_param[PARAM_W_MEAN] = mean; 
      next_param[PARAM_STD] = NaN(); 
      next_param[PARAM_W_STD] = NaN(); 
      next_param[PARAM_MEDIAN] = mean; 
      next_param[PARAM_Q1] = mean; 
      next_param[PARAM_Q2] = mean; 
      next_param[PARAM_01] = 0.99f*mean;  // These parameters are used for setting inital limits 
      next_param[PARAM_99] = 1.01f*mean;  // so must be different to mean for correct display

      SetNaN(next_param+PARAM_ERR_LOWER,1);
      SetNaN(next_param+PARAM_ERR_UPPER,1);

      next_param += N_STATS;

      idx++;
   }

   /**
    * Set the next parameter to @mean, parameter has no variance 
    */
   void SetNextParam(T mean, T err_lower, T err_upper)
   {

      next_param[PARAM_MEAN] = mean; 
      next_param[PARAM_W_MEAN] = mean; 
      next_param[PARAM_STD] = NaN(); 
      next_param[PARAM_W_STD] = NaN(); 
      next_param[PARAM_MEDIAN] = mean; 
      next_param[PARAM_Q1] = mean; 
      next_param[PARAM_Q2] = mean; 
      next_param[PARAM_01] = 0.99f*mean;  // These parameters are used for setting inital limits 
      next_param[PARAM_99] = 1.01f*mean;  // so must be different to mean for correct display

      next_param[PARAM_ERR_LOWER] = err_lower;
      next_param[PARAM_ERR_UPPER] = err_upper;

      next_param += N_STATS;

      idx++;
   }

private:

   T* params;
   T* next_param;
   int idx;

};

#endif