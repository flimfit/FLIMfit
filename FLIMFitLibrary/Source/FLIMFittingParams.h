class FLIMFittingParams
{
public:

   bool ValidateParams();

   FLIMFittingParams(int global_mode, 
                     int n_exp, int n_fix,
                     int single_guess, double tau_guess,
                     int fit_beta, double *fixed_beta,
                     int fit_offset, double offset_guess,
                     int fit_scatter, double scatter_guess,
                     int fit_tvb, double tvb_guess,
                     int pulsetrain_correction, double t_rep,
                     int ref_reconvolution, double ref_lifetime_guess,
                     int calculate_errors);

   int SetFRETParams(int n_fret, int n_fret_fix, double *E_guess);
   int SetPolarisationResolvedParams(int n_theta, int n_theta_fix, double *theta_guess;);

   int global_mode;

   bool polarisation_resolved;
   
   int n_exp; 
   int n_fix; 

   double *tau_min; 
   double *tau_max;
   
   int single_guess; 
   double *tau_guess;
   
   int fit_beta; 
   double *fixed_beta;
   
   int n_theta;
   int n_theta_fix;
   double *theta_guess;

   int fit_t0; 
   double t0_guess; 
   
   int fit_offset; 
   double offset_guess; 
   
   int fit_scatter; 
   double scatter_guess;

   int fit_tvb; 
   double tvb_guess; 
   double *tvb_profile;
   
   int fit_fret; 
   int inc_donor; 
   
   int n_fret; 
   int n_fret_fix; 
   double *E_guess; 

   int pulsetrain_correction; 
   double t_rep;

   int ref_reconvolution; 
   double ref_lifetime_guess;

   int calculate_errs;
}

bool FLIMFittingParams::ValidateParams()
{
   if (n_fix > n_exp)
      n_fix = n_exp;

   for (int i=0; i<n_exp; i++)
   {
      if (tau_min[i] >= tau_max[i])
         tau_min[i] = tau_max[i] - 100;
   }

   return true;
}


int SetFRETParams(int n_fret, int n_fret_fix, int inc_donor, double *E_guess)
{
   polarisation_resolved = false;
   n_theta     = 0;
   n_theta_fix = 0;
   n_theta_v   = 0;
   theta_guess = NULL;
   n_r         = 0;
   n_pol_group = 1;
     
   fit_fret         = true;
   this->n_fret     = n_fret;
   this->n_fret_fix = n_fret_fix;
   this->inc_donor  = inc_donor;
   this->E_guess    = E_guess;

   if (n_fret_fix > n_fret)
      n_fret_fix = n_fret;

   return 0;
}

int SetPolarisationResolvedParams(int n_theta, int n_theta_fix, double *theta_guess)
{
   fit_fret   = false;
   n_fret     = 0;
   n_fret_fix = 0;
   n_fret_v   = 0;
   inc_donor  = true;
   E_guess    = NULL;

   polarisation_resolved = true;
   this->n_theta         = n_theta;
   this->n_theta_fix     = n_theta_fix;
   this->theta_guess     = theta_guess;

   n_theta_v = n_theta - n_theta_fix; 

   if (fit_beta == FIT_LOCALLY)
      fit_beta = FIT_GLOBALLY;

   return 0;
}

FLIMFittingParams(int global_mode, 
                  int n_exp, int n_fix,
                  int single_guess, double tau_guess,
                  int fit_beta, double *fixed_beta,
                  int fit_offset, double offset_guess,
                  int fit_scatter, double scatter_guess,
                  int fit_tvb, double tvb_guess,
                  int pulsetrain_correction, double t_rep,
                  int ref_reconvolution, double ref_lifetime_guess,
                  int calculate_errors) :
   global_mode(global_mode),
   n_exp(n_exp), n_fix(n_fix),
   single_guess(single_guess), tau_guess(tau_guess)
   fit_beta(fit_beta), fixed_beta(fixed_beta),
   fit_offset (fit_offset), offset_guess(offset_guess),
   fit_scatter (fit_scatter), scatter_guess(scatter_guess), 
   fit_tvb (fit_tvb), tvb_guess(tvb_guess),
   pulsetrain_correction (pulsetrain_correction), t_rep(t_rep),
   ref_reconvolution(ref_reconvolution), ref_lifetime_guess(ref_lifetime_guess),
   calculate_errors(calculate_errors)
{
   fit_fret   = false;
   n_fret     = 0;
   n_fret_fix = 0;
   n_fret_v   = 0;
   inc_donor  = true;
   E_guess    = NULL;
   
   polarisation_resolved = false;
   n_theta     = 0;
   n_theta_fix = 0;
   n_theta_v   = 0;
   theta_guess = NULL;
   n_r         = 0;
   n_pol_group = 1;

   if (global_mode == MODE_GLOBAL_BINNING)
      n_fix = n_exp;
}