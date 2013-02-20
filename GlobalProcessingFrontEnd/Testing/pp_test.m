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

N = 256;
t = (0:(N-1))' / N * 20e3;
g = normpdf(t,4000,900);

ex = 3 * exp(-t/1000);
ex = ex + 5 * exp(-t/3000);

ex = ex * 1e5;
ex(t<0) = 0;

f = conv(ex,g,'full');
f = f(1:length(t));

fact = norm(f);

f_noise = poissrnd(f)/fact;
f = f/fact;

subplot(3,1,1);
plot(t,g);
subplot(3,1,2);
plot(t,ex);
subplot(3,1,3);
plot(t,f);
hold on
plot(t,f_noise,'r');
hold off;

%tau = phase_plane_estimation(t,g,f_noise,1);
%disp(tau')

tau = phase_plane_estimation(t,g,f_noise,2);
disp(tau')

%tau = phase_plane_estimation(t,g,f_noise,3);
%disp(tau./[3000; 5000]')
