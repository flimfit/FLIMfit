addpath('../FLIMfitLibrary/FLIMreader');

root = '/Users/sean/Documents/FLIMTestData/';

folder = [root '2015-07-02 CFP-GFP cells/'];

files = [dir([folder '4 *.pt3']); ...
         dir([folder '2 *.pt3']); ...
         dir([folder '7 *.pt3'])];

background_file = 'no sample background_19_1.pt3';
GetBackground([folder background_file]);
     
irf_phasor = GetIRFPhasor([folder 'fitted-irf.csv']);


%%

folder = '/Volumes/Seagate Backup Plus Drive/FLIM Data/2015-07-16 Dual FRET mouse/'

background_file = 'background 3min _46_1.pt3';
GetBackground([folder background_file]);

files = [dir([folder '01 Control*.pt3'])];
%%

ra = GetIRFPhasor([folder 'rfp-autofluorescence.csv']);

%%
irf_file = [folder 'reference.csv'];

irf_phasor = GetIRFPhasor(irf_file);

omega = 2*pi/12500;
tau_ref = [7181.2; 6818.5; 6083];
    
cor = (1 + 1i * omega * tau_ref) ./ (1 + (omega*tau_ref).^2);
    
irf_phasor = irf_phasor ./ cor;


%%

folder = [root '2015-07-08 MutRac dual cells/'];
files = dir([folder '*.pt3']);

%%

folder = [root '2015-07-02 CFP-GFP cells/'];

files = [dir([folder '2 *.pt3']); ...
         dir([folder '4 *.pt3']); ...
         dir([folder '7 *.pt3'])];
     
     
%%

folder = ['/Volumes/Seagate Backup Plus Drive/FLIM Data/2015-07-03 RhoRac dual mouse/'];
files = [dir([folder '03*.pt3']); dir([folder '04*.pt3']); dir([folder '05*.pt3'])];
    
%%



lim1 = [0.0 0.5];
lim2 = [0.0 0.5];

h = waitbar(0,'Processing...');

for i=1:length(files) 
   
    filename = [folder files(i).name];
    
    [data, t] = LoadImage(filename);
    sz = size(data);
        
    [p, I] = CalculatePhasor(t, data, irf_phasor, background);
    
    kern = fspecial('disk',3);
    p = reshape(p,sz(2:4));
    
    for j=1:size(p,1)
        p(j,:,:) = imfilter(squeeze(p(j,:,:)), kern, 'replicate');
    end
    
    p = reshape(p,[sz(2), sz(3)*sz(4)]);
    
    
    figure(1);
    DrawPhasor(p,I);
    %{
    subplot(1,2,2)
    RI = squeeze((sum(data(:,1,:,:),1)));
    imagesc(RI)
    %}
    drawnow;
    [Af,kf,Ff,rf] = FitFRETPhasorMex(p,I);
    disp('.')
    
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
    PlotMerged(r.E_CFP, r.A_CFP, lim1)
    title(files(i).name,'Interpreter','None')

    subplot(2,1,2);
    PlotMerged(r.E_GFP, r.A_GFP, lim2);
    title('GFP')

    sel = ~isnan(r.A_GFP);
    res = sum(r.res(sel).*r.A_GFP(sel)) / sum(r.A_GFP(sel));
    
    disp(['Residual: ' num2str(res)]);

    g = sum(r.A_GFP(sel));
    c = sum(r.A_CFP(sel));
    
    disp(['Fraction GFP: ' num2str(g / (g+c))]);
    
    drawnow;
    
    save([filename '-no-RAF.mat'],'r');
    
    waitbar(i/length(files),h);
    
end

close(h); 

disp('Done.')
%%
ShowResults(folder, '-fixed-k-2');

%%

lim1 = [0 1];
lim2 = [0 1];

subplot(2,1,1);
PlotMerged(r.E_CFP, r.A_CFP, lim1)
title(files(i).name,'Interpreter','None')

subplot(2,1,2);
PlotMerged(r.E_GFP, r.A_GFP, lim2);
title('GFP')