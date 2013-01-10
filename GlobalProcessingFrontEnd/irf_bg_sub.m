
irf_file = 'Y:\User Lab Data\Doug Kelly\2012\08 August\2012-08-02 Calibration Dyes Old HRI\Eryth 20uM\2012-08-02 17-59-55 INT_001000 T_02500.tif';
bg_file = 'Y:\User Lab Data\Doug Kelly\2012\08 August\2012-08-02 Calibration Dyes Old HRI\MilliQ\2012-08-02 19-35-11 INT_001000 T_02500.tif';

[t,irf]  = load_flim_file(irf_file);
[t,data] = load_flim_file(bg_file);

%%

sz = size(irf);

irf = reshape(irf,[sz(1) prod(sz(2:end))]);
data = reshape(data,[sz(1) prod(sz(2:end))]);

%%

bg_sub = irf - data;

%%

write_flim_tifs('Y:\User Lab Data\Doug Kelly\2012\08 August\2012-08-02 Calibration Dyes Old HRI\Background Subtracted IRF\',t,bg_sub)

%%
figure

a = mean(irf,2)-200;
b = mean(bg_sub,2);
c = mean(irf,2)-mean(data,2);

semilogy([a/max(a) b/max(b) c/max(c)])