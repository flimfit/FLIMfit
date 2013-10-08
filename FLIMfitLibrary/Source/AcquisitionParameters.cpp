#include "AcquisitionParameters.h"


AcquisitionParameters::AcquisitionParameters(int data_type, int polarisation_resolved, int n_chan, int n_t_full, int n_t, double t_[], double t_int_[], int t_skip_[], double t_rep, double counts_per_photon) :
   data_type(data_type),
   polarisation_resolved(polarisation_resolved),
   n_chan(n_chan),
   n_t_full(n_t_full),
   n_t(n_t),
   t_rep(t_rep),
   counts_per_photon(counts_per_photon)
{
   t_skip.assign(n_chan, 0);

   n_meas = n_chan * n_t;
      
   if (t_skip_ != NULL)
   {
      for(int i=0; i<n_chan; i++)
         t_skip[i] = t_skip_[i];
   }

   // Copy t and t_int
   t.resize(n_t);
   t_int.resize(n_t);

   int i0 = t_skip[0];
   for(int i=0; i<n_t; i++)
   {
      t[i] = t_[i + i0];
      t_int[i] = t_int_[i + i0];
   }

}

double* AcquisitionParameters::GetT()
{
   return &t[0];
}
