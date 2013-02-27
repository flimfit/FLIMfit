function t_min = optimise_gating_fisher

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

    tau = [3 2];
    beta = [0.5 0.5];
    I0 = 200;
    
    n_t = 4;
    t = (0:(n_t-1))/(n_t-1) * 10;
    
    
    opt = optimset('PlotFcns',{@optimplotx,@optimplotfval});
    
    %t_min = fminsearch(@fisher_det,t,opt);
    
    t_min = ga(@fisher_det,n_t,[],[],[],[],0,10);
    
    function j = fisher_det(t)

        n_exp = length(tau);
        n_t = length(t);
        
        if n_exp == 1
            n_p = 1;
        else
            n_p = 2*n_exp;
        end
        
        dp = zeros(n_p,n_t);
        p = zeros(1,n_t);
        F = zeros(n_p+1,n_p+1);

        for i=1:n_t
            if t(i) < 0
                p(i) = 0;
                dp(:,i) = 0;
            else
                
                p(i) = sum( beta .* exp(-t(i)./tau) );
                if n_exp > 1
                    dp(1:n_exp,i) = exp(-t(i)./tau);
                    dp((n_exp+1):end,i) = beta.*t(i).*(tau.^-2).*exp(-t(i)./tau);
                else
                    dp(1,i) = t(i).*(tau.^-2).*exp(-t(i)./tau);
                end
            end
        end

        N = I0 * sum(p);
        
        p = p ./ sum(p);

        for i=1:n_p
            for j=1:i
                F(i+1,j+1) = sum(dp(i,:) .* dp(j,:) ./ p);
                F(j+1,i+1) = F(i+1,j+1);
            end
        end

        F(1,1) = 1/N;
        
        j = det(F);
       
        
    end
    


end
