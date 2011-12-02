loadlibrary('FLIMGlobalAnalysisDLL','FLIMGlobalAnalysis.h');

[t,data] = open_flim_files([],'Z:\Users\scw09\Matlab\GenerateFLIMTestData\TestData2\data\fr000del000500.tif');
n_t = length(t);

n_im = 10;

data = reshape(data,[size(data) 1]);
data = repmat(data,[1 1 1 n_im]);

data = data;
t = t + 0;

width = size(data,3);
height = size(data,2);

mask = ones(size(data,2),size(data,3),size(data,4));
n_group = 10;
n_px = n_im * width * height / n_group;

[t_irf,irf] = load_irf_file('Z:\Users\scw09\Matlab\GenerateFLIMTestData\TestData2\irf\fr000del000000.tif');
n_irf = length(irf);

irf_padding = 4-mod(n_irf,4); % 4;
t_irf = [t_irf; zeros(irf_padding, 1)];
irf = [irf zeros(1, irf_padding)];

n_thread = 16;

%{
tau1 = 1000;
tau2 = 2000;

t = 0:100:10000;
data = 2000 * exp(-t/tau1) + 1000 * exp(-t/tau2);

irf = 1;
t_irf = 0;
n_irf = 1;


n_px = 1;
%}
n_exp = 2;
n_fix = 0;
tau_guess = [2400 1000];
fit_t0 = 0;
t0_guess = 0;
fit_offset = 0;
offset_guess = 0;

tau = zeros([n_exp n_group]);
I0 = zeros([n_px n_group]);
beta = zeros([n_exp n_px n_group]);
chi2 = zeros([n_group 1]);
ierr = zeros([n_group 1]);
t0 = zeros([n_group 1]);
offset = zeros([n_group 1]);


p_t = libpointer('doublePtr',t);
p_data = libpointer('doublePtr', data);
p_mask = libpointer('int32Ptr', mask);
p_tau_guess = libpointer('doublePtr',tau_guess);
p_irf  = libpointer('doublePtr', irf);
p_t_irf = libpointer('doublePtr', t_irf);
p_tau = libpointer('doublePtr', tau);
p_I0 = libpointer('doublePtr', I0);
p_beta = libpointer('doublePtr', beta);
p_chi2 = libpointer('doublePtr', chi2);
p_ierr = libpointer('int32Ptr', ierr);
p_t0 = libpointer('doublePtr', t0);
p_offset = libpointer('doublePtr',offset);

tic
%[~,~,~,~,~,~,~,~,~,tau,I0,beta,chi2,ierr] ...
calllib('FLIMGlobalAnalysisDLL','FLIMGlobalFit', ...
                        0, n_group, n_px, p_data, p_mask, ...
                        n_t, p_t, n_irf, p_t_irf, p_irf, ...
                        n_exp, n_fix, p_tau_guess, ...
                        fit_t0, t0_guess, fit_offset, offset_guess, ...
                        p_tau, p_I0, p_beta, p_t0, p_offset, ...
                        p_chi2, p_ierr, n_thread, true, false, 0);
                    
group = zeros(1,n_thread);
n_completed = zeros(1,n_thread);
iter = zeros(1,n_thread);
chi2 = zeros(1,n_thread);
progress = 0.0;

h_wait = waitbar(0,'Fitting...');

%t = timer('TimerFcn',@update_progress, 'ExecutionMode', 'fixedDelay', 'Period', 0.05);
%start(t)

finished = false;

while ~finished
%function update_progress(~,~)
[finished, group, n_completed, iter, chi2, progress] ...
    = calllib('FLIMGlobalAnalysisDLL','FLIMGetFitStatus', group, n_completed, iter, chi2, progress); 
    waitbar(progress,h_wait)
    
end

        close(h_wait);
        
        disp(toc)                    

        beta = p_beta.Value;
        I0 = p_I0.Value;
        chi2 = p_chi2.Value;
        ierr = p_ierr.Value;
        tau = p_tau.Value;
        offset = p_offset.Value;
        t0 = p_t0.Value;
       
        beta = reshape(beta,[n_exp height width n_im]);
        I0 = reshape(I0,[height width n_im]);
        tau = reshape(tau,[n_exp n_group]);

        subplot(2,1,1)
        imagesc(squeeze(beta(1,:,:,1)),[0 1])
        colorbar
        subplot(2,1,2)
        imagesc(squeeze(I0(:,:,1)))
        colorbar

        unloadlibrary('FLIMGlobalAnalysisDLL');
    



