function [counts_per_photon offset] = determine_photon_stats(data,fit_offset,display_progress)

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


    if nargin < 2
        fit_offset = true;
    end
    
    if nargin < 3
        display_progress = true;
    end

    figure();
    ax = axes();
    
    
    % Number of points we will use to calculate the variance
    n_req = 100;
    
    % Number of time to repeat the calculation at diffent histogram
    % positions
    N = 50;

    % Reshape data if required, e.g. if images are passed
    sz = size(data);
    data = reshape(data,[sz(1) prod(sz(2:end))]);
    
    % Calculate intensity
    I = squeeze(sum(data,1));
    
    mi = mean(data-200,1);
    si = std(data-200,1);
    
    
    % Number of repeats for each different intensity 
    n = length(I);

    Nc = 10;
    
    % The fraction of those points we need either side of the chosen pt
    frac = n_req/n;
    
    % The histogram positions to use
    pos = linspace(0.5,0.9,N);
    
    sel_data = zeros(sz(1),n_req,N,Nc);
    
    
    for i=1:N

        % select data around the histogram position
        centre = pos(i);
        Q = quantile(I,[centre-frac,centre+frac]); 
        dQ = Q(2)-Q(1);
        Q0 = Q(1);
        for j=1:Nc
            sel = I >= (Q0+(j-1)*dQ) & I <= (Q0+j*dQ);       
            sd = data(:,sel);
            sel_data(:,:,i,j) = sd(:,1:n_req);
        end
    end
    
    if fit_offset
        initial_guess = [15 200 5];
    else
        initial_guess = 15;
    end

    c = 0;
    counts_per_photon = [];
    offset = [];
    for i=1:Nc
        z = sel_data(:,:,:,i);
        [o,f] = fminsearch(@objt,initial_guess);
        counts_per_photon(i) =  o(1);
        if (fit_offset)
            offset(i) = o(2);
        end
    end
    
    if fit_offset
        offset = o(2);
    else
        offset = 0;
    end
    
    subplot(1,1,1);
    plot(counts_per_photon);
 
    
    st = ['Counts per photon = ' num2str(mean(counts_per_photon),'%.2f') ' +/- ' num2str(std(counts_per_photon),2)];
    disp(st);
    disp(['           Offset = ' num2str(mean(offset),'%.2f') ' +/- ' num2str(std(offset),2)])

    %{
    hold(ax,'off')
    plot(ax,pos,counts_per_photon);
    xlabel(ax,'Sample')
    ylabel(ax,'Counts per photon');
    title(ax,st)
    %}
    counts_per_photon = mean(counts_per_photon);
    offset = mean(offset);
    
    function r = objt(m) 
    
        alpha = m(1);
        
        if fit_offset
            g = m(2);
            sigma_ccd = m(3);
        else
            g = 192.77;
            sigma_ccd = 1.375;
        end
        
        %sigma_ccd = 2.12;
        
        % Apply anscrombe transform
        antr = 2/alpha*sqrt(alpha*z+3/8*alpha^2+sigma_ccd^2-alpha*g);
        
        thresh = (-3/8*alpha - sigma_ccd^2/alpha + g);
        
        antr(z < thresh) = 0;
        
        
        % Calculate mean and std
        s = squeeze(std(antr,0,2))-1;
        mn = squeeze(mean(antr,2));
        
        % Determine sum of square residuals
        r = s.*s;
        r = trimmean(r,30,2);
        r = trimmean(r,30,1);
        %r = median(r(:));
                
        if display_progress && mod(c,10) == 0
            ax1=subplot(1,2,1);
            imagesc(s);
            %caxis([-3 3])
            colorbar;
            subplot(1,2,2);
            plot(sum(s,2),'o-');
            %plot(ax,mn,ones(size(s)),'k'); 
            %ylim([0.8 1.2]);
            %hold(ax,'on');
            %plot(ax,mn,s.*s,'o');
            %ylabel(ax,'Variance');
            %xlabel(ax,'Corrected Photon Count');
            title(ax1,num2str(m));
            drawnow;
        end
        c=c+1;
    end

end

