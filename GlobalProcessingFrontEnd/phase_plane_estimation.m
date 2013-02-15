function [tau] = phase_plane_estimation(t_f,g,f,N)

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



    %#codegen
    
    n_f = length(t_f);
    
    F = zeros(n_f,N);
    G = zeros(n_f,N);
    
    F(:,1) = cumtrapz(t_f,f,1);
    G(:,1) = cumtrapz(t_f,g,1);
    
    for i=2:N
        F(:,i) = cumtrapz(t_f,F(:,i-1),1);
        G(:,i) = cumtrapz(t_f,G(:,i-1),1);
    end

    A = [-F G];

    x = pinv(A)*f;
   
    %res = (A*x-f);
    %S = nansum(res.^2)/(n_f-N);
    
    c = [1; x(1:N)];
    
    c = flipud(c);
    alt = double(((-1).^(0:N))');
    tau = roots(c.*alt);
        
end