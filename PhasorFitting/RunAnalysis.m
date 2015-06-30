
irf_file = '/Users/sean/Documents/FLIMTestData/2015-06-26 RacRho/irf.csv';
folder = '/Users/sean/Documents/FLIMTestData/2015-06-26 RacRho/'; 

irf_phasor = GetIRFPhasor(irf_file);

files = dir([folder '*.pt3']);

lim1 = [0 0.4];
lim2 = [0.2 0.6];

h = waitbar(0,'Processing...');

for i=1:length(files) 
   
    filename = [folder files(i).name];
    
  
    token = regexp(files(i).name,'_(\d+)\.pt3','tokens');
    idx = num2str(token{1}{1});
    
    if mod(idx,2) == 0 % skip files with EX at 960 
        continue
    end
    
    
    [data, t] = LoadImage(filename);
    sz = size(data);
    
    [p, I] = CalculatePhasor(t, data, irf_phasor);
    
    [Af,kf] = FitFRETPhasorMex(p,I);
    
    Ef = kf./(1+kf);

    Af = reshape(Af,sz(2:end));
    Ef = reshape(Ef,sz(2:end));

    r.A_CFP = squeeze(Af(1,:,:));
    r.A_GFP = squeeze(Af(2,:,:));
    r.E_CFP = squeeze(Ef(1,:,:));
    r.E_GFP = squeeze(Ef(2,:,:));

    subplot(2,1,1);
    PlotMerged(r.E_CFP, r.A_CFP, lim1)
    title(files(i).name)

    subplot(2,1,2);
    PlotMerged(r.E_GFP, r.A_GFP, lim2);
    title('GFP')
    
    drawnow;
    
    save([filename '.mat'],'r');
    
    waitbar(i/length(files),h);
    
end

close(h);