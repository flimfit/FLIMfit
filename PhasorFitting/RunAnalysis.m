addpath('../FLIMfitLibrary/FLIMreader');
%%

folder = '/Users/sean/Documents/FLIMTestData/2015-07-02 CFP-GFP cells/';

reference_file = 'green chroma slide _38_1.pt3';
background_file = 'no sample background_19_1.pt3';
[reference, t] = LoadImage([folder reference_file]); 
[background] = LoadImage([folder background_file]); 

sz = size(reference);
reference = reshape(reference,[sz(1:2) prod(sz(3:4))]);
reference = mean(reference,3);
%%
background = reshape(background,[sz(1:2) prod(sz(3:4))]);
background = mean(double(background),3);

reference = reference - background;

%%

irf_file = [folder 'irf.csv'];

irf_phasor = GetIRFPhasor(irf_file);


%%


mex FRETPhasor.cpp 'CXXFLAGS="$CXXFLAGS -std=c++11 -O3"' -I/usr/local/include -L/usr/local/lib -lnlopt


files = [dir([folder '4 *.pt3']); ...
         dir([folder '2 *.pt3']); ...
         dir([folder '7 *.pt3'])];

lim1 = [0 0.5];
lim2 = [0.0 0.5];

h = waitbar(0,'Processing...');

for i=1:length(files) 
   
    filename = [folder files(i).name];
    
  
    token = regexp(files(i).name,'_(\d+)\.pt3','tokens');
    idx = num2str(token{1}{1});
    
    %if mod(idx,2) == 0 % skip files with EX at 960 
    %    continue
    %end
    
    
    [data, t] = LoadImage(filename);
    sz = size(data);
        
    [p, I] = CalculatePhasor(t, data, irf_phasor, background);
    
    [Af,kf,rf] = FitFRETPhasorMex(p,I);
    
    Ef = kf./(1+kf);

    If = sum(I,1);
    If = reshape(If, sz(3:4));
    Af = reshape(Af,[2, sz(3:4)]);
    Ef = reshape(Ef,[2, sz(3:4)]);
    rf = reshape(rf,sz(3:4));

    r.A_CFP = squeeze(Af(1,:,:));
    r.A_GFP = squeeze(Af(2,:,:));
    r.E_CFP = squeeze(Ef(1,:,:));
    r.E_GFP = squeeze(Ef(2,:,:));
    r.res = rf;
    r.I = If;

    subplot(2,1,1);
    PlotMerged(r.E_CFP, r.A_CFP, lim1)
    title(files(i).name,'Interpreter','None')

    subplot(2,1,2);
    PlotMerged(r.E_GFP, r.A_GFP, lim2);
    title('GFP')

    %{
    subplot(2,1,3);
    PlotMerged(sqrt(r.res), r.A_CFP+r.A_GFP, [0 10]);
    %imagesc(I);
    %daspect([1 1 1]);
    %set(gca,'YTick',[],'XTick',[]);
    title('total intensity')
    %}
    sel = ~isnan(r.A_GFP);
    res = sum(r.res(sel).*r.A_GFP(sel)) / sum(r.A_GFP(sel));
    
    disp(['Residual: ' num2str(res)]);

    g = sum(r.A_GFP(sel));
    c = sum(r.A_CFP(sel));
    
    disp(['Fraction GFP: ' num2str(g / (g+c))]);
    
    drawnow;
    
    save([filename '-fixed-k-2.mat'],'r');
    
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