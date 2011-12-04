function simulate_data

nx = 128;
ny = 128;
nt = 256;

t = 0:(nt-1);
t = t/nt*12.5e3;

tau1 = 4000;
tau2 = 1800;

irf = normpdf(t,1000,200);

tg = t(2)-t(1);

decay1 = tau1*(1-exp(-tg/tau1))*exp(-t/tau1);
decay2 = tau2*(1-exp(-tg/tau2))*exp(-t/tau2);

normf = max(decay1);

decay1 = decay1 / normf;
decay2 = decay2 / normf;

I0_min = 200;
I0_max = 10000;

data = zeros([nt nx ny]);

noise_mu = 0;
noise_sigma = 0;

file = 'sim10.raw';
irf_file = 'irf.irf';

dlmwrite(irf_file,[t' irf'],'\t');

for x=1:nx
    for y=1:ny
        a1 = (x-1)/(nx-1);
        a2 = 1 - a1;
        
        I = I0_min + (I0_max-I0_min) * (y-1)/(ny-1);
        
        decay = I * (a1*decay1  + a2*decay2);
        decay = conv(irf,decay);
        decay = decay(1:nt);

        decay = poissrnd(decay) + round(normrnd(noise_mu,noise_sigma,size(decay)));
        
        a(x,y) = a1;
        data(:,x,y) = decay;
        
        
    end 
end

dinfo = struct();
dinfo.t = t;
dinfo.names = {'simulated_data'};
dinfo.metadata = struct('FileName',{'simulated_data'});
dinfo.channels = 1;
dinfo.data_size = [nt 1 nx ny 1];
dinfo.polarisation_resolved = false;
dinfo.num_datasets = 1;
dinfo.mode = 'TCSPC';

fname = [tempname '.mat'];
save(fname,'dinfo');
fid = fopen(fname,'r');
byteData = fread(fid,inf,'uint8');
fclose(fid);
delete(fname);

mapfile = fopen(file,'w');      

fwrite(mapfile,length(byteData),'uint16');
fwrite(mapfile,byteData,'uint8');
fwrite(mapfile,data,'uint16');
fclose(mapfile);

SaveFPTiff(a1,'a1.tif');

end