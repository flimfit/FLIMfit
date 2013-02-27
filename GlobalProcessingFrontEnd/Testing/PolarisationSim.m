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


n = 256;
dt = 50;

t = (1:2*n)*dt;

irf_c = 2000;
irf_w = 400;

irf_off = 0;

tau = 4000;
tau_ref = 80;
theta = 200;

t_rep = 12.5e3;

irf_para = exp(-(t-irf_c).^2/irf_w^2) + exp(-(t-irf_c-t_rep).^2/irf_w^2);
irf_para = irf_para/sum(irf_para);

irf_perp = exp(-(t-irf_c-irf_off).^2/irf_w^2) + exp(-(t-irf_c-t_rep-irf_off).^2/irf_w^2);
irf_perp = irf_perp/sum(irf_perp);


It = 10e4 * exp(-t/tau);

I_ref = 10e4 * exp(-t/tau_ref);

r = exp(-t/theta);

para = It .* 1/3 .* (1 + 2 * r);
perp = It .* 1/3 .* (1 - r);

para_c = conv(para,irf_para);
perp_c = conv(perp,irf_perp);


para_ref_c = conv(I_ref,irf_para);
perp_ref_c = conv(I_ref,irf_perp);

para_ref_c = para_ref_c(1:length(irf_para));
perp_ref_c = perp_ref_c(1:length(irf_perp));

para_c = para_c(1:length(irf_para));
perp_c = perp_c(1:length(irf_perp));

%perp_c = interp1(t,perp_c,t+50);

irf_para = irf_para * 5e4;
irf_perp = irf_perp * 5e4;

perp_c = para_c + 3*irf_perp;


sel = (n+1):(2*n);

irf_para = irf_para(sel);
irf_perp = irf_perp(sel);

para_ref_c = para_ref_c(sel);
perp_ref_c = perp_ref_c(sel);

para_c = para_c(sel);
perp_c = perp_c(sel);
t = t(1:n);

subplot(1,2,1)
semilogy(t,[para_c' perp_c' irf_para' irf_perp']);
ylim([0.1 max(para_c)])

subplot(1,2,2)

anis = (para_c - perp_c) ./ (para_c + 2* perp_c);

plot(anis)

%{
folder = 'C:\Users\scw09\Documents\00 Local FLIM Data\2011-06-08 Pol Sim\';



dlmwrite([folder 'decay.txt'],[t' para_c' perp_c']);
dlmwrite([folder 'irf.txt'],[t' irf_para' irf_perp']);
dlmwrite([folder 'ref.txt'],[t' para_ref_c' perp_ref_c']);
%}