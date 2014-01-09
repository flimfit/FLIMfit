function irf_data = generate_t0_map(obj, mask, dataset)

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

    prof = get_profile();  
    
    max_shift = prof.Tools.IRF_Shift_Map_Max_Shift;
    downsampling = prof.Tools.IRF_Shift_Map_Max_Downsampling;
    
    decay = obj.get_roi(mask, dataset);
    decay = mean(decay,3);
    decay(decay<0) = 0;

    n = downsampling;
    nt = 5;
    
    diff = zeros(obj.height/n,obj.width/n);
    sim = zeros(obj.height/n,obj.width/n);
    intensity = zeros(obj.height/n,obj.width/n);
    
    ti = obj.tr_t;
    tii = (min(ti)-max_shift):nt:(max(ti)+max_shift);
    
    decayi = interp1(ti,decay,tii,'linear',0);
    decayi = decayi/sum(decayi);
    
    shifted = [];
    original = [];
    
    h=waitbar(0,'Calculating offsets');
    for i=1:(obj.width/n)
        for j=1:(obj.height/n)
            
            decayij = obj.cur_tr_data(:,:,j*n,i*n);   
            mask = obj.mask(j*n,i*n);
            decayij(decayij<0) = 0;
            
            if ~mask
            
                intensity(j,i) = NaN;
                diff(j,i) = NaN;
                sim(j,i) = NaN;
                
            else
                
                decayiji = interp1(ti,decayij,tii,'linear',0);

                intensity(j,i) = sum(decayiji);

                decayiji = decayiji / intensity(j,i);

                [a,lags] = xcorr(decayi,decayiji,max_shift/nt);
                [m,idx] = max(a);
                sim(j,i) = m;
                diff(j,i) = lags(idx)*nt;
               
                
                decayx = interp1(ti,decayij,ti-diff(j,i),'linear',0)';
                
                
                m = decay \ decayx;

                
                shifted(:,end+1) = decayx / m;
                original(:,end+1) = decayij / m;
                
                r = decay - decayx / m;
                r = r(isfinite(r));
                sim(j,i) = norm(r)/length(r);
                
                
            end
        end
        
        
        if mod(i,20)
            waitbar(i/obj.width*n,h);
        end
    end
    close(h);
    diff = imresize(diff,n,'nearest');
    
    f=figure('Units','Pixels');
    p = get(f,'Position');
    p(2:4) = [200,400,600];
    set(f,'Position',p);
    
    %subplot(1,3,1);
    %plot(obj.tr_t,decay);
    %title('Decay Shape');
    
    subplot(2,1,1);
    imagesc(diff);
    daspect([1,1,1]);
    colorbar
    set(gca,'YTick',[],'XTick',[])
    title('IRF Shift (ps)')

    subplot(2,1,2);
    imagesc(sim/max(sim(:)));
    daspect([1,1,1]);
    colorbar
    colormap('hot');
    set(gca,'YTick',[],'XTick',[])
    title('Degree of correlation (Normalised)');

    
    %figure()
    
    %subplot(1,2,1);
   
    s2 = size(shifted,2);
    t = obj.tr_t';
    t = [t(1); t; t(end)];
    tx = repmat(t,[1, size(shifted,2)]);
    
    padding = -100*ones(1,s2);
    original = [padding; original; padding];
    %{
    patchline(tx,original,'FaceColor','none','EdgeAlpha',0.02)
    ylim([0 1.1*max(original(:))])
   
    subplot(1,2,2)
    %}
    %{
    shifted = [padding; shifted; padding];
    
    patchline(tx,shifted,'FaceColor','none','EdgeAlpha',0.02)
    ylim([0 1.1*max(shifted(:))])
    xlabel('Time (ps)');
    ylabel('Normalised Response')
   %}
    %{
    subplot(2,2,4);
    imagesc(intensity);
    daspect([1,1,1]);
    colorbar
    title('Intensity (DN)');
    %}
    avg_diff = nanmean(diff(:));
    diff(~isfinite(diff)) = avg_diff;
    
    % If we don't have an IRF loaded, use the decay.
    % Otherwise use the loaded IRF.
    if size(obj.tr_irf,1) > 3         
        irf_data = struct('t_irf',obj.tr_t_irf,'irf',obj.tr_irf,'t0_image',diff);       
    else
        irf_data = struct('t_irf',obj.tr_t,'irf',decay,'t0_image',diff);
    end
    
    
    
end