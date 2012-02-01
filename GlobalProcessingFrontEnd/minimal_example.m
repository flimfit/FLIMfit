function [Itot, f_1, tau_1, tau_2, decay, chi2 ] = minimal_example(t,data,mask,t_irf,irf,bg,t0,rep_rate)

addpath_global_analysis();

%%%% Initialise the data series to load from memory
data_series = flim_data_series();
data_series_controller = flim_data_series_controller('data_series',data_series);

%%% Set the data and IRF
%%% data should be of size [n_t height width n_images]
%%% you must set an irf, should have at least three points eg [0 1 0]
data_series.set_data(t,data);
data_series.set_irf(t_irf,irf);

data_series.seg_mask = mask;

%%% Optional transformations
%data_series.binning = 1;
%data_series.downsampling = 1;

%data_series.t_min = 0;
%data_series.t_max = 0;
%data_series.thresh_min = 0;
%data_series.thresh_max = 0;
%data_series.t_irf_min = 0;
%data_series.t_irf_max = 0;
%data_series.irf_background = 0;

%data_series.background_type = bg_type.none; % no background

%data_series.background_type = bg_type.constant; % constant value
%data_series.background_value = bg;

%data_series.background_type = bg_type.image; % background image
%data_series.background_image = background_image; % same size as data!

%%% Initialise the fitting parameters
fitting_params = flim_fitting_params();
fitting_params.n_exp = 2;
fitting_params.n_fix = 0;
fitting_params.global_fitting = 0; % 0=pixel wise, 1=imagewise, 2=global
fitting_params.fit_offset = 0;
fitting_params.fit_scatter = 0;

fitting_params.t0 = t0;
fitting_params.offset = bg;
fitting_params.scatter = 0;

fitting_params.rep_rate = rep_rate; %80e6;
fitting_params.ref_lifetime = 20;

fitting_params.pulsetrain_correction = false;
%fitting_params.pulsetrain_correction = true; %YA

fitting_params.ref_reconvolution = false;

fitting_params.tau_guess = [4000; 200]; % must be in descending order

fitting_params.tau_min = [0; 0];
%fitting_params.tau_max = [10000; 10000];
fitting_params.tau_max = [20000; 20000]; %YA

%fitting_params.n_thread = 8; %automatically set to number of processors if
%not specified

hx = gcf;

%%% Initialise the fitting controller
fit_controller = flim_fit_controller('data_series_controller',data_series_controller,'fit_params',fitting_params);
addlistener(fit_controller,'fit_completed',@(src,evt)fit_complete(src,evt,hx));

%%% finally, fit the data! 
fit_controller.fit();
if fit_controller.has_fit == 0
    uiwait(hx);
end

%%% Get the fit results
fit_result = fit_controller.fit_result();
images = fit_result.images; % now images contains all the fitting results
param_table = fit_controller.param_table; % summary table of results
param_table_headers = fit_controller.param_table_headers; % table headers

decay = fit_controller.fitted_decay(t,1,1);

images = images{1};

tau_2 = images.tau_1;
tau_1 = images.tau_2;
    A_2 = images.beta_1; 
    A_1 = images.beta_2; 

if isfinite(tau_1) && isfinite(tau_2) && isfinite(A_1) && isfinite(A_2) && A_2>0 && A_1>0
    Itot = A_1*tau_1 + A_2*tau_2;
    f_1 = A_1*tau_1/Itot;
    chi2 = fit_result.chi2;
else
    Itot = 0;
    f_1 = 0;
    chi2 = 0;
    tau_1 = 0;
    tau_2 = 0;    
end

%disp([tau_1 tau_2 fit_result.ierr])

function fit_complete(~,~,hx)
    uiresume(hx);
end

end
