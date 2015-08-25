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
    ProcessFLIMImage(filename, irf_phasor, background);
    waitbar(i/length(files),h);
    
end

close(h); 

disp('Done.')
%%
ShowResults(folder, '-fixed-k-2');
