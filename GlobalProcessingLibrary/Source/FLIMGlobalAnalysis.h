/* =============================================
 * FLIMGlobalFit.h
 * v0.1  7 June 2010
 * Sean Warren, Imperial College London.
 *
 * Header file for FLIM Global Fitting library.
 *
 * =============================================
 */

#ifndef _FLIMGLOBALFIT_
#define _FLIMGLOBALFIT_

#define _CRTDBG_MAPALLOC  

#include "FlagDefinitions.h"


#ifdef _WINDOWS
#define FITDLL_API __declspec(dllexport)
#else
#define FITDLL_API 
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned short uint16_t;

FITDLL_API int FLIMGlobalGetUniqueID();
FITDLL_API void FLIMGlobalRelinquishID(int id);


FITDLL_API int SetupGlobalFit(int c_idx, int global_algorithm, 
                              int n_irf, double t_irf[], double irf[], double pulse_pileup,
                              int n_exp, int n_fix,  double tau_min[], double tau_max[], 
                              int estimate_initial_tau, int single_guess, double tau_guess[],
                              int fit_beta, double fixed_beta[],
                              int fit_t0, double t0_guess, 
                              int fit_offset, double offset_guess, 
                              int fit_scatter, double scatter_guess,
                              int fit_tvb, double tvb_guess, double tvb_profile[],
                              int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                              int pulsetrain_correction, double t_rep,
                              int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                              double tau[], double I0[], double beta[], double E[], double gamma[],
                              double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                              int calculate_errs, double tau_err[], double beta_err[], double E_err[],
                              double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                              double chi2[], int ierr[],
                              int n_thread, int runAsync, int use_callback, int (*callback)());

FITDLL_API int SetupGlobalPolarisationFit(int c_idx, int global_algorithm,
                             int n_irf, double t_irf[], double irf[], double pulse_pileup,
                             int n_exp, int n_fix, 
                             double tau_min[], double tau_max[], 
                             int estimate_initial_tau, int single_guess, double tau_guess[],
                             int fit_beta, double fixed_beta[],
                             int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                             int fit_t0, double t0_guess,
                             int fit_offset, double offset_guess, 
                             int fit_scatter, double scatter_guess,
                             int fit_tvb, double tvb_guess, double tvb_profile[],
                             int pulsetrain_correction, double t_rep,
                             int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                             double tau[], double I0[], double beta[], double theta[], double r[], 
                             double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                             int calculate_errs, double tau_err[], double beta_err[], double theta_err[],
                             double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                             double chi2[], int ierr[],
                             int n_thread, int runAsync, int use_callback, int (*callback)());

FITDLL_API int SetDataParams(int c_idx, int n_im, int n_x, int n_y, int n_chan, int n_t_full, double t[], int t_skip[], int n_t,
                             int data_type, int* use_im, int *mask, int threshold, int limit, int global_mode, int smoothing_factor, int use_autosampling);

FITDLL_API int SetDataDouble(int c_idx, double* data);
FITDLL_API int SetDataUInt16(int c_idx, uint16_t* data);
FITDLL_API int SetDataFile(int c_idx, char* data_file, int data_class, int data_skip);

FITDLL_API int SetBackgroundImage(int c_idx, double* background_image);
FITDLL_API int SetBackgroundValue(int c_idx, double background_value);

FITDLL_API int StartFit(int c_idx);













/* =============================================
 * FLIMGlobalFit
 * =============================================
 *
 * Performs global, NLLS fitting by variable projection on FLIM data. 
 * Model assumes data of form:
 *
 *                         n_exp
 * y(g, s, t) = I0(g, s) * SUM   beta(g, s, i) * exp[ (t - t0) / tau(g, i) ]  + offset(g),
 *                         i=0
 * 
 * convolved with an arbitary, user provided IRF.
 *
 * Fitting is based on the VarPro Netlib code.
 
 *
 * INPUT PARAMETERS
 * ---------------------------
 * n_group                 Number of groups of pixels to fit. Tau's will be fixed within groups 
 * n_px                    Number of pixels in each group
 * n_regions               [n_group] array indicating number of regions within each group
 * data[]                  [n_group, n_px, n_t] array of measured decays
 * global_mode             Reserved for future use
 * mask[]                  [n_group, n_px, n_t] array indicating which which region each pixel belongs to. 
                           Zero indicates the pixel is excluded from any fit 
 * n_t                     Number of timepoints in each measurement
 * t[]                     [n_t] array of gate/bin times in ps
 * n_irf                     Number of points in IRF
 * t_irf                   [n_irf] array of time points for IRF measurements
 * irf                     [n_irf] array of irf measurements
 * n_exp                   Number of exponential species to fit
 * n_fix                   Number of exponential species which have fixed tau values
 * tau_guess[]             [n_exp] array of initial estimates for tau values. First n_fix will be treated as fixed.
 * fit_t0                  Reserved for future use. Set to zero.
 * t0_guess                Initial guess for t0 (zero timepoint). Fixed if fit_t0 = false 
 * fit_offset              Indicates whether to fit an offset. Possible values:
                              0 FIX          Fix the offset to the guess provided
                              1 FIT_LOCALLY  Fit the offset as a local parameter, i.e. seperately for each pixel
                              2 FIT_GLOBALLY Fit the offset as a global parameter, i.e. across all pixels in the group
 * offset_guess            Inital guess for offset
 * fit_scatter             Indicates whether to fit a 'scatter' component. Possible values:
                              0 FIX          Fix the scatter to the guess provided
                              1 FIT_LOCALLY  Fit the scatter as a local parameter, i.e. seperately for each pixel
                              2 FIT_GLOBALLY Fit the scatter as a global parameter, i.e. across all pixels in the group
 * scatter_guess           Initial guess for scatter contribution 

 * fit_fret                Reserved for future use. Set to zero
 * E_guess                Reserved for future use. Set to zero

 * pulsetrain_correction   Indicates whether to account for incomplete decays
 * t_rep                   Repetition rate of laser,  used for pulse train correction. Ignored if pulsetrain_correction = false
 * ref_reconvolution       Indicates whether to use reference reconvolution, i.e. if the IRF was taken using a fluorophore
 * ref_lifetime            Lifetime of reference fluorophore. Ignored if ref_reconvolution = false
 * algorithm               Indicate whether to use Levenberg–Marquardt or Gauss-Newton update rule. In general LM should be used,
                           GN may provide more reliable results for single exponential fits with very few gates.
                              0 LM  Use Levenberg–Marquardt update rule
                              1 GN  Use Gauss-Newton update rule
 *
 * OUTPUT PARAMETERS (memory must be allocated on entry)
 * -----
 * tau[]        [n_group, n_px, n_exp] array of fitted (and fixed) tau values for each pixel
 * I0[]         [n_group, n_px] array of pixel intensities. Zero for masked values
 * beta[]       [n_group, n_px, n_exp] array of fractional pre-exponetial factors
 * E[]         Reserved for future use. Set to NULL
 * t0[]         [n_group, n_px] array of zero timepoints
 * offset[]     [n_group, n_px] array of measurement offsets
 * scatter[]    [n_group, n_px] array of scatter contributions
 * chi2[]       [n_group] array of chi2 values
 * ierr[]       [n_group] array of return parameters. Positive values indicate the number of iterations taken for a 
                successful fit. Negative values indicate failure and correspond to Varp2 error codes
 *
 * CONFIGURATION PARAMETERS
 * ----- 
 * n_thread     Number of threads to use when fitting. Should be twice the number of processors
 * run_async    Indicates whether the function should run asyncronously 
 * use_callback Indicates whether the program should periodicaly call 'callback' with a status update 
 *              Note that the function will be called from a different thread to the main program
 * callback     If running asyncronously will be called periodically with current group, iteration and chi2
 *              Fitting will stop if zero returned. Not called if NULL, progress may be monitored by calling FLIMGlobalGetFitStatus
 *              Expected function prototype is int callback(int n_group, int n_thread, int *group, 
 *                                                          int *n_completed, int *iter, double *chi2, double progress)
 *              All arrays are of size n_thread.
 *        
 *
 * RETURN VALUE
 * -----
 * 0     Success
 * ...
 */
/*
FITDLL_API int FLIMGlobalFit(int c_idx, int n_group, int n_px, int n_regions[], int global_mode,
                             int data_type, double data[], int mask[],
                             int n_t, double t[],
                             int n_irf, double t_irf[], double irf[], double pulse_pileup,
                             int n_exp, int n_fix, 
                             double tau_min[], double tau_max[], 
                             int single_guess, double tau_guess[],
                             int fit_beta, double fixed_beta[],
                             int fit_t0, double t0_guess, 
                             int fit_offset, double offset_guess, 
                             int fit_scatter, double scatter_guess,
                             int fit_tvb, double tvb_guess, double tvb_profile[],
                             int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                             int pulsetrain_correction, double t_rep,
                             int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                             double tau[], double I0[], double beta[], double E[], double gamma[],
                             double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                             int calculate_errs, double tau_err[], double beta_err[], double E_err[],
                             double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                             double chi2[], int ierr[],
                             int n_thread, int run_async, int use_callback, int (*callback)());
*/

/* =============================================
 * FLIMGlobalFitMemMap
 * =============================================
 *
 * Memory mapped version of FLIMGlobalFit.
 * Parameters as FLIMGlobalFit with the exception of data. 
 * Here data is the path to a file containing the FLIM data.
 *
 */
 /*
FITDLL_API int FLIMGlobalFitMemMap(int c_idx, int n_group, int n_px, int n_regions[], int global_mode,
                             int data_type, char* data_file, int mask[],
                             int n_t, double t[],
                             int n_irf, double t_irf[], double irf[], double pulse_pileup,
                             int n_exp, int n_fix, 
                             double tau_min[], double tau_max[], 
                             int single_guess, double tau_guess[],
                             int fit_beta, double fixed_beta[],
                             int fit_t0, double t0_guess, 
                             int fit_offset, double offset_guess, 
                             int fit_scatter, double scatter_guess,
                             int fit_tvb, double tvb_guess, double tvb_profile[],
                             int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                             int pulsetrain_correction, double t_rep,
                             int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                             double tau[], double I0[], double beta[], double E[], double gamma[], 
                             double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                             int calculate_errs, double tau_err[], double beta_err[], double E_err[],
                             double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                             double chi2[], int ierr[],
                             int n_thread, int runAsync, int use_callback, int (*callback)());


FITDLL_API int FLIMGlobalPolarisationFitMemMap(int c_idx, int n_group, int n_px, int n_regions[], int global_mode,
                             int data_type, char* data_file, int mask[],
                             int n_t, double t[],
                             int n_irf, double t_irf[], double irf[], double pulse_pileup,
                             int n_exp, int n_fix, 
                             double tau_min[], double tau_max[], 
                             int single_guess, double tau_guess[],
                             int fit_beta, double fixed_beta[],
                             int use_magic_decay, double magic_decay[],
                             int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                             int fit_t0, double t0_guess,
                             int fit_offset, double offset_guess, 
                             int fit_scatter, double scatter_guess,
                             int fit_tvb, double tvb_guess, double tvb_profile[],
                             int pulsetrain_correction, double t_rep,
                             int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                             double tau[], double I0[], double beta[], double theta[], double r[], 
                             double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                             int calculate_errs, double tau_err[], double beta_err[], double theta_err[],
                             double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                             double chi2[], int ierr[],
                             int n_thread, int runAsync, int use_callback, int (*callback)());


FITDLL_API int FLIMGlobalPolarisationFit(int c_idx, int n_group, int n_px, int n_regions[], int global_mode,
                             int data_type, double data[], int mask[],
                             int n_t, double t[],
                             int n_irf, double t_irf[], double irf[], double pulse_pileup,
                             int n_exp, int n_fix, 
                             double tau_min[], double tau_max[], 
                             int single_guess, double tau_guess[],
                             int fit_beta, double fixed_beta[],
                             int use_magic_decay, double magic_decay[],
                             int n_theta, int n_theta_fix, int inc_rinf, double theta_guess[],
                             int fit_t0, double t0_guess,
                             int fit_offset, double offset_guess, 
                             int fit_scatter, double scatter_guess,
                             int fit_tvb, double tvb_guess, double tvb_profile[],
                             int pulsetrain_correction, double t_rep,
                             int ref_reconvolution, double ref_lifetime_guess, int algorithm,
                             double tau[], double I0[], double beta[], double theta[], double r[], 
                             double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                             int calculate_errs, double tau_err[], double beta_err[], double theta_err[],
                             double offset_err[], double scatter_err[], double tvb_err[], double ref_lifetime_err[],
                             double chi2[], int ierr[],
                             int n_thread, int runAsync, int use_callback, int (*callback)());


FITDLL_API int FLIMGlobalGetChi2Map(int c_idx, int data_type, double data[], int n_t, double t[],
                                    int n_irf, double t_irf[], double irf[], double pulse_pileup,
                                    int n_exp, int n_fix, 
                                    double tau_min[], double tau_max[], double tau_guess[],
                                    int fit_beta, double fixed_beta[],
                                    int fit_t0, double t0_guess, 
                                    int fit_offset, double offset_guess, 
                                    int fit_scatter, double scatter_guess,
                                    int fit_tvb, double tvb_guess, double tvb_profile[],
                                    int n_fret, int n_fret_fix, int inc_donor, double E_guess[],
                                    int pulsetrain_correction, double t_rep,
                                    int ref_reconvolution, double ref_lifetime_guess,
                                    int grid_size, double grid[], 
                                    double tau[], double I0[], double beta[], double E[], double gamma[],
                                    double t0[], double offset[], double scatter[], double tvb[], double ref_lifetime[],
                                    double chi2[],
                                    int runAsync, int use_callback, int (*callback)());
*/
                                    

/* =============================================
 * FLIMGlobalGetFitStatus
 * =============================================
 *
 * Returns the status of an asyncronous fitting process
 *
 * OUTPUT PARAMETERS (memory must be allocated on entry)
 * ---------------------------
 * group[]       Indicates which group each thread is currently processing
 * n_completed[] Number of groups each thread has completed
 * iter[]        Current iteration of group each thread is processing
 * chi2[]        Current Chi^2 value of group each thread is processing
 * progress      Fractional overall progress
 *
 * RETURN VALUE
 * ---------------------------
 * 0             Success, incomplete
 * 1             Success, fitting completed
 * ERR_NOT_INIT  Not initialised

 */
FITDLL_API int FLIMGetFitStatus(int c_idx, int *group, int *n_completed, int *iter, double *chi2, double *progress);


/* =============================================
 * FLIMGlobalTerminateFit
 * =============================================
 *
 * Termiate an asyncronous fitting process
 *
 * RETURN VALUE
 * ---------------------------
 * 0            Success
 * ERR_NOT_INIT Not initalised
 *
 */
FITDLL_API int FLIMGlobalTerminateFit(int c_idx);


/* =============================================
 * FLIMGlobalGetFit
 * =============================================
 *
 * Returns fitted decays at arbitary time points. 
 * Must be called after FLIMGlobalFit has completed.
 *
 * INPUT PARAMETERS
 * ---------------------------
 * group    Group index from which fit should be retrieved
 * n_fit    Number of pixels requested
 * mask[]   [n_px] array, mask indicating pixels to return
 * n_t      Number of timepoints required
 * t[]      [n_t] array of timepoints required
 *
 * OUTPUT PARAMETERS (memory must be allocated on entry)
 * ---------------------------
 * fit[]   [n_fit, n_t] array of fitted decays. Failed pixels return NaN
 *
 */
FITDLL_API int FLIMGlobalGetFit(int c_idx, int ret_group_start, int n_ret_groups, int n_fit, int fit_mask[], int n_t, double t[], double fit[]);

/* =============================================
 * FLIMGlobalClearFit
 * =============================================
 *
 * Clear fitted data saved from a call to FLIMGlobalFit
 *
 */
FITDLL_API int FLIMGlobalClearFit(int c_idx);


/* =============================================
 * FLIMGlobalSimulateData
 * =============================================
 *
 *   Simulate FLIM data
 *
 * INPUT PARAMETERS
 * ---------------------------
 * n_px                    Number of pixels in each group
 * n_t                     Number of timepoints in each measurement
 * t[]                     [n_t] array of gate/bin times in ps
 * n_irf                     Number of points in IRF
 * t_irf                   [n_irf] array of time points for IRF measurements
 * irf                     [n_irf] array of irf measurements
 * n_exp                   Number of exponential species to fit
 * tau[]                   [n_exp] array of initial estimates for tau values. First n_fix will be treated as fixed.
 * fit_t0                  Reserved for future use
 * t0_guess                Initial guess for t0 (zero timepoint). Fixed if fit_t0 = false 

 *
 * OUTPUT PARAMETERS (memory must be allocated on entry)
 * ---------------------------
 * fit[]   [n_fit, n_t] array of fitted decays. Failed pixels return NaN
 *
 *
 */
/*
FITDLL_API int FLIMSimulateData(int n_px, int n_t, double t[],
                                int n_irf, double t_irf[], double irf[],
                                int n_exp, double tau[],
                                double I0[], double beta[],
                                double offset, double scatter, 
                                int pulsetrain_correction, double t_rep,
                                double data[]);
                                */



#ifdef __cplusplus
}
#endif
#endif
