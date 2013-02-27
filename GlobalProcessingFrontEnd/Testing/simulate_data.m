function [noisy_data, data, mask, beta] = simulate_data(tau,t,px_photons,t_irf,irf,noise_mean,noise_std,path)

% Copyright (C) 2013 Imperial College London.
% All rights reserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
% This software tool was developed with support from the UK 
% Engineering and Physical Sciences Council 
% through  a studentship from the Institute of Chemical Biology 
% and The Wellcome Trust through a grant entitled 
% "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

% Author : Sean Warren

addpath('../FLIMGlobalAnalysisLibraries');
addpath('../FLIMMatlabUtilities');

if ~libisloaded('FLIMGlobalAnalysisDLL')
    loadlibrary('FLIMGlobalAnalysisDLL','FLIMGlobalAnalysis.h');
end


%{
I0 = imread('sim/sim_I0.tif');
mask = imread('sim/sim_mask.tif');
mask(mask > 0) = 1;
%}

n = 256;
I0 = ones(n);
mask = ones(n);


I0(mask==0) = 0;

if length(tau) == 1
    beta = ones(size(I0));
else
    
    beta = (1:size(I0,2)) / size(I0,2);
    beta = repmat(beta,[size(I0,1) 1]);

    beta = reshape(beta,[1 size(beta,1) size(beta,2)]);
    beta = repmat(beta,[2 1 1]);
    beta(1,:,:) = 1-beta(1,:,:);
end

n_t = length(t);
n_px = length(I0(:));
n_irf = length(irf);
n_exp = length(tau);

offset = 0;
scatter = 0;

pulsetrain_correction = 1;
t_rep = 1/80e6;

data_size = [n_t size(I0,1) size(I0,2)];

    
data = libpointer('doublePtr',zeros(data_size));

calllib('FLIMGlobalAnalysisDLL','FLIMSimulateData',n_px,n_t,t,n_irf,t_irf,irf,n_exp,tau,I0,...
    beta,offset,scatter,pulsetrain_correction,t_rep,data);

d = get(data, 'Value');
data = reshape(d,data_size);

data_mask = reshape(mask,[1 size(mask,1) size(mask,2)]);
data_mask = repmat(data_mask,[n_t 1 1]);
data(data_mask==0) = 0;

n = squeeze(sum(data,1));
n = mean(n(n>0));
data = data / n * px_photons;


%data = data / max(data(:)) * px_photons;


noisy_data = zeros(size(data));
for i=1:n_t
    noisy_data(i,:,:) = poissrnd(data(i,:,:)) + normrnd(noise_mean,noise_std,[1 size(data,2) size(data,3)]);
end
noisy_data = round(noisy_data);
%noisy_data = data;

if nargin == 8

    if ~exist(path,'dir')
        mkdir(path)
    end

    delete([path '/*.tif']);

    for p = 1:n_t
        tmp = squeeze(noisy_data(p,:,:));
        tmpi = uint16(tmp);
        name = sprintf([path '/fr000del%06.0f.tif'],t(p));
        imwrite(tmpi,name,'tif');
    end  

    f = fopen([path '/Parameters.txt'],'w');
    fprintf(f,'FLIM data generated using simulate_data.m\r\n\r\n');
    fprintf(f,'tau1 = %d ps\r\n',tau(1));
    fprintf(f,'tau2 = %d ps\r\n',tau(2));
    fprintf(f,'px_photons = %d\r\n',px_photons);
    fprintf(f,'noise = shot + gaussian (mu = %d, sigma = %d)\r\n',noise_mean,noise_std);
    fclose(f);
    
end
    
    



