function sim_plot_beta_map(est_beta_map,avg,tau2,lim,offset)

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

if nargin < 4
    offset = 0;
end

Nh = size(est_beta_map,2);
Nw = size(est_beta_map,1);

clf();
h = gcf();
set(h,'position',[0 0 800 800]);
ha = tight_subplot(h,Nh*Nw,Nh,Nw,[5 5],[45 5],[45 60],'pixels');

k = 0;
for j=1:Nh
    for i=1:Nw
        k = k + 1;
        disp([i j])
        imagesc(squeeze(est_beta_map{i,j}-offset),'Parent',ha(k));
        set(ha(k),'YTick',[]);
        set(ha(k),'XTick',[]);
        caxis(ha(k),lim);
        if j == Nh
            label = num2str(avg(i));
            xlabel(ha(k),label)
            if i == ceil(Nw/2)
                xlabel(ha(k),{label; 'Photons/px'})
            end
        end
        if i == 1
            label = num2str(3750-tau2(j));
            ylabel(ha(k),label)
            if j == ceil(Nh/2)
                ylabel(ha(k),{'\tau_{D}-\tau_{DA}';label})
            end
        elseif i==Nw
            w=15;
            a=5;
            pos=get(ha(k),'position');
            colorbar('peer',ha(k),'location','EastOutside','units','pixels','position',[pos(1)+pos(3)+5 pos(2)+a w pos(4)-a*2]);
            set(ha(k),'position',pos);
        end
    end
end