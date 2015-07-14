%%
folder = [root '2015-07-13 Dual Reference/']
reference_file = '01 Atto488 _2_1.pt3';
background_file = '01 no sample _3_1.pt3';
[reference, t] = LoadImage([folder reference_file]); 
[ref_background] = LoadImage([folder background_file]); 

sz = size(reference);
reference = reshape(reference,[sz(1:2) prod(sz(3:4))]);
reference = mean(reference,3);

ref_background = reshape(ref_background,[sz(1:2) prod(sz(3:4))]);
ref_background = mean(double(ref_background),3);

reference = reference - ref_background;

csvwrite([folder 'reference.csv'],[t, reference]);

%%
irf_phasor = GetIRFPhasor([folder 'fitted-irf.csv']);

omega = 2*pi/12500;
tau_ref = 4259;
    
cor = (1 + 1i * omega * tau_ref) ./ (1 + (omega*tau_ref).^2);
    
%irf_phasor = irf_phasor ./ cor;