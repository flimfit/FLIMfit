
#ifndef _IRFCONV_H
#define _IRFCONV_H

#include "FLIMGlobalFitController.h"

#define N_EXP_BUF_ROWS 6

void calc_exps(FLIMGlobalFitController *gc, int n_t, double t[], int total_n_exp, double tau[], int n_theta, double theta[], double exp_buf[]);

void conv_irf_tcspc(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double& c);
void conv_irf_timegate(FLIMGlobalFitController *gc, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], int k, int i, double& c);

void conv_irf_deriv_tcspc(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c);
void conv_irf_deriv_timegate(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c);

void conv_irf_deriv_ref_tcspc(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c);
void conv_irf_deriv_ref_timegate(FLIMGlobalFitController *gc, double t, double rate, double exp_irf_buf[], double exp_irf_cum_buf[], double exp_irf_tirf_buf[], double exp_irf_tirf_cum_buf[], int k, int i, double ref_fact, double& c);

void conv_irf_ref(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double beta[], int dim, double a[], int add_components = 0, int inc_beta_fact = 0);
void conv_irf_diff_ref(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int n_tau, double tau[], double beta[], int dim, double b[], int inc_tau = 1);


int flim_model(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double a[], int add_components = 0, int inc_beta_fact = 0, int inc_ref_deriv_fact = 0);
int flim_model_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int n_tau, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double b[], int inc_tau = 1, double* donor_tau = 0);
int flim_fret_model_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], double tau[], double beta[], double ref_lifetime, int dim, double b[]);

int anisotropy_model(FLIMGlobalFitController *gc, int n_t, double t[], double decay_buf[], int n_theta, double theta[], double ref_lifetime, int dim, double a[]);
int anisotropy_model_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int n_tau, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double b[]);

int ref_lifetime_deriv(FLIMGlobalFitController *gc, int n_t, double t[], double exp_buf[], int total_n_exp, double tau[], double beta[], int n_theta, double theta[], double ref_lifetime, int dim, double b[]);

void sample_irf(FLIMGlobalFitController *gc, double a[], int pol_group = 0, double* scale_fact = 0);


inline double anscombe(double x)
{
   return 2 * sqrt(x + 0.375);
}

inline double inv_anscombe(double x)
{
   return x*x*0.25 - 0.375;
}

inline double anscombe_diff(double x)
{
   return 1 / sqrt(x + 0.375);
}



#endif