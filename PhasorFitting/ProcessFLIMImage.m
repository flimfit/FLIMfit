function ProcessFLIMImage(filename, irf_phasor, background, annotation)
    
    % Load data
    [data, t] = LoadImage(filename);
    sz = size(data);
        
    % Calculate phasors
    [p, I] = CalculatePhasor(t, data, irf_phasor, background);
    
    % Smooth phasor
    kern = fspecial('disk',3);
    p = reshape(p,sz(2:4));
    for j=1:size(p,1)
        p(j,:,:) = imfilter(squeeze(p(j,:,:)), kern, 'replicate');
    end
    p = reshape(p,[sz(2), sz(3)*sz(4)]);
    
    % Display phasor
    figure(1);
    DrawPhasor(p,I);
    ylim([0.3 0.6]);
    xlim([0.2 0.8]);
    drawnow;

    % Fit FRET and extract results
    [Af,kf,Ff,rf] = FitFRETPhasorMex(p,I);
    
    Ef = kf./(1+kf);

    Ii = reshape(I, sz(2:4));
    pi = reshape(p, sz(2:4));
    
    If = sum(I,1);
    If = reshape(If, sz(3:4));
    Af = reshape(Af,[2, sz(3:4)]);
    Ef = reshape(Ef,[2, sz(3:4)]);
    rf = reshape(rf,sz(3:4));
    Ff = reshape(Ff,sz(3:4));
    
    r.A_CFP = squeeze(Af(1,:,:));
    r.A_GFP = squeeze(Af(2,:,:));
    r.E_CFP = squeeze(Ef(1,:,:));
    r.E_GFP = squeeze(Ef(2,:,:));
    r.res = rf;
    r.Isum = If;
    r.I = Ii;
    r.RAF = Ff;
    r.phasor = pi;
    
    figure(2);
    subplot(2,1,1);
    PlotMerged(r.E_CFP, r.A_CFP, [0 0.5])
    title(filename,'Interpreter','None')

    subplot(2,1,2);
    PlotMerged(r.E_GFP, r.A_GFP, [0 0.5]);
    title('GFP')

    sel = ~isnan(r.A_GFP);
    res = sum(r.res(sel).*r.A_GFP(sel)) / sum(r.A_GFP(sel));
    
    disp(['Residual: ' num2str(res)]);

    g = sum(r.A_GFP(sel));
    c = sum(r.A_CFP(sel));
    
    disp(['Fraction GFP: ' num2str(g / (g+c))]);
    
    drawnow;
    
    save_filename = strrep(filename, '.pt3', [annotation '.mat']);
    save(save_filename,'r');
end
    