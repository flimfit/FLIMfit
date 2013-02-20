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


t = 1:20:5e4;

irf = zeros(size(t));
irf(200:300) = 1;

taut = 1000:100:4000;
betat = normpdf(taut,6000,3000);

decay = 0;
for i=1:length(taut)
   
    decay = decay + exp(-t/taut(i)) * betat(i); 
    
end

y = conv(irf,decay);

y = y / max(y);

y = y * 10e3;

y = poissrnd(y);

y = y(1:length(t));

subplot(2,1,1)
plot(t,[y;decay;irf])
%plot(taut,betat);

tau=100:100:10000;
n = length(tau);

C = []; 

for i=1:n
   
    d = exp(-t/tau(i));
    d = conv(irf,d);
    d = d(1:length(t));
    
    C = [C; d];
    
end

lb = zeros(size(tau));
options = optimset('Diagnostics','off','LargeScale','off','MaxIter',400);
x = lsqlin(C',y',[],[],[],[],lb,[],lb,options);
subplot(2,1,2)
plot(tau,x)
