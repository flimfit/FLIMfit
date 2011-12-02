function optimise_gating_strategy()

addpath('../FLIMGlobalAnalysisLibraries');
loadlibrary('FLIMGlobalAnalysisDLL','FLIMGlobalAnalysis.h');

addpath('../FLIMMatlabUtilities');

[t_irf_wf,irf_wf] = open_flim_files('','sim/irf7.irf');
irf_wf = irf_wf ./ norm(irf_wf(:));

t = [0 1000 2000 3000 4000 5000 6000];   

avg = 500;

tau1 = 3250;
tau2 = 3750;



lb = zeros(size(t));
ub = ones(size(t))*12e3;

figure();    
h = gca;

%options = psoptimset('PlotFcns',{@psplotbestf,@psplotbestx});
%t_opt = patternsearch(@objective,t,[],[],[],[],lb,ub,options);

options = gaoptimset('PlotFcns',{@gaplotbestf,@gaplotscores});
x = ga(@objective,length(t),[],[],[],[],zeros(size(t)),[],[],options);

%t_opt = fminsearch(@objective,t,...
%    optimset('PlotFcns',@optimplotx));

disp(x);





function beta_err_norm = objective(t)

    persistent best best_t
    
    t = t * 10000;
    
    global_mode = 'global';
    fit_mode = 0;
   
    [noisy_data data mask beta] = simulate_data([tau1 tau2],t,avg,t_irf_wf,irf_wf,200,5);

    [tau_est, beta_est, I0_est] = fit_test_data(t,noisy_data,mask,[tau1 tau2],t_irf_wf,irf_wf,global_mode,1,200,fit_mode);

    beta_err = beta_est(1,:,:) - beta(1,:,:);
    beta_err_norm = nansum(abs(beta_err(:)));

    if beta_err_norm == 0
        beta_err_norm = 1e10;
    end
    
    n_exp = 2;
    n_px = size(I0_est,1) * size(I0_est,2);
    
    tau_sq = reshape(tau_est,[n_exp,n_px]);
    tau_sq = mean(tau_sq,2);
    
    disp(['tau = ' mat2str(tau_sq)]);
    disp(['t = ' mat2str(t)]);
    disp(['beta_err_norm = ' num2str(beta_err_norm)]);
    
    if isempty(best) || beta_err_norm < best
        best = beta_err_norm;
        best_t = sort(t);

        di = squeeze(beta_est(1,:,:));
        imagesc(di,'Parent',h);
        colorbar('Peer',h);
        caxis(h,[0 1]);
        pause(0.00001);
    end
    
    disp(['best t = ' mat2str(best_t)]);
    
    

    
    
    

end

end
%semilogy(t,d);
