addpath('../FLIMfitLibrary/FLIMreader');

root = '/Users/sean/Documents/FLIMTestData/';

folder = [root '2015-07-02 CFP-GFP cells/'];

files = [dir([folder '4 *.pt3']); ...
         dir([folder '2 *.pt3']); ...
         dir([folder '7 *.pt3'])];

%%
%reference_file = 'green chroma slide _38_1.pt3';
background_file = 'no sample background_19_1.pt3';
%[reference, t] = LoadImage([folder reference_file]); 
[background] = LoadImage([folder background_file]); 

sz = size(background);
%reference = reshape(reference,[sz(1:2) prod(sz(3:4))]);
%reference = mean(reference,3);

background = reshape(background,[sz(1:2) prod(sz(3:4))]);
background = mean(double(background),3);

%reference = reference - background;

%%

irf_phasor = GetIRFPhasor([folder 'fitted-irf.csv']);

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

files = [dir([folder '7 *.pt3']); ...
         dir([folder '4 *.pt3']); ...
         dir([folder '2 *.pt3'])];
     
     
%%

folder = [root '2015-07-03 RhoRac dual mouse/'];
files = dir([folder '04*.pt3']);
files = [files; dir([folder '05*.pt3'])];
    
%%



lim1 = [0.0 0.5];
lim2 = [0.0 0.5];

h = waitbar(0,'Processing...');

for i=1:length(files) 
   
    filename = [folder files(i).name];
    
    [data, t] = LoadImage(filename);
    sz = size(data);
        
    [p, I] = CalculatePhasor(t, data, irf_phasor, background);
    
    p = reshape(p,[])
    
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
    
    save([filename '.mat'],'r');
    
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