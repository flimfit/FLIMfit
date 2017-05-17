function estimate_irf_background(obj)
    
%> Estimate the IRF background level.
    
% Try to fit to two gaussians, one for peak and one for background. 
% Theoretically not as good as fitting to a gauss + constant but seems 
% to converge better. In general the background just has a very large 
% sigma. The background is the mean of the smaller 'peak'
    
    
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


    for i=1:size(obj.irf,2)

        ir = double(obj.irf(:,i));
        
        if sum(ir==0) > 0.5 * length(ir)
            bg(i) = 0;
        else            

            [xData, yData] = prepareCurveData(obj.t_irf, ir);

            % Fit gaussian with offset
            ft = fittype( 'a*exp(-b*(x-x0)^2)+c', 'independent', 'x', 'dependent', 'y' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.Lower = [0 0 0 min(obj.t_irf)];

            % Set sensible start points
            [max_irf,max_loc] = max(ir);
            t_max = obj.t_irf(max_loc);
            opts.StartPoint = [max_irf 1e-5 min(ir) t_max];

            % Fit model to data.
            [fitresult] = fit( xData, yData, ft, opts );

            bg(i) = fitresult.c;
            
        end
        
    end

    obj.irf_background = max(bg);
    
end
