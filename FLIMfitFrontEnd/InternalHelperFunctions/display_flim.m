function im=display_flim(data,mask,lim,varargin)

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

    m = 2^8;
    w = ceil(size(data,2) * 0.05);
    w = max(w, 10);
    
    options = struct();
    merge = false;
    

    for i=1:length(varargin)
        if isstruct(varargin{i})
            options = varargin{i};
        elseif isnumeric(varargin{i})
            intensity = varargin{i};
            merge = true;
        end
    end
    
    if ~isfield(options,'cscale')
        options.cscale = @jet;
    end
    if ~isfield(options,'t')
        options.t = '';
    end
    if ~isfield(options,'int_lim')
        options.int_lim = prctile(intensity(:),95);
    end
    if ~isfield(options,'gamma')
        prof = get_profile();  
        options.gamma = prof.Display.Gamma_Factor;
    end
    if ~isfield(options,'show_colormap')
        options.show_colormap = false;
    end
    if ~isfield(options,'show_limits')
        options.show_limits = false;
    end


    
    h1 = size(data,1);
    cbar = (h1:-1:1)';
    cbar = repmat(cbar,[1,w]);
        
    % scale to lie between 1-2^8 
    data = (data - lim(1))/(lim(2)-lim(1));
    nan_mask = isnan(data);

    if merge
        ibar = (1:w)/w;
        ibar = repmat(ibar,[h1,1]);
        
        data(data < 0) = 0;
        data(data > 1) = 1;  
        data = int32(data * (m-1) + 1);

        cmap = options.cscale(h1);
        cbar = ind2rgb(cbar,cmap);
        
        cmap = options.cscale(m);
        mapped_data = ind2rgb(data,cmap);

        intensity(intensity>options.int_lim(2)) = options.int_lim(2);
        intensity = intensity - options.int_lim(1);
        intensity(intensity<0 | isnan(intensity)) = 0;
        intensity = intensity / (options.int_lim(2)-options.int_lim(1));
        
        intensity = intensity .^ options.gamma;

        cbar = cbar .* repmat(ibar,[1 1 3]);
        mapped_data = mapped_data .* repmat(intensity, [1 1 3]);
        
    else
        
        data = int32(data * (m-1) + 1);

        %data(data < 0) = -1; % out of range below -> dark gray
        %data(data > m) = 0; % out of range above -> light gray
        
        data(data<1) = 1;
        data(data>m) = m;
        
        data(nan_mask) = -2; % failed to fit -> white

        if ~isempty(mask)
            data(mask==1) = -3; % masked -> black
        end
        
        data = data + 4;

        cmap = options.cscale(m);
        cmap = [ [0,0,0]; [1,1,1]; [0.33,0.33,0.33]; [0.66,0.66,0.66]; cmap];

        mapped_data = mat2im(data,cmap);

        cmap = options.cscale(h1);
        cbar = ind2rgb(cbar,cmap);
    end
    
    if options.show_colormap
        im = [mapped_data cbar];
    else
        im = mapped_data;
    end
   
    if options.show_limits
        font_size = ceil(size(data,1) * 0.03);
        font_size = max(font_size,8);
        im = insertText(im,[size(data,1) 1],num2str(lim(2)),'AnchorPoint','RightTop',...
            'Font','Arial','FontSize',font_size,'TextColor','white','BoxColor','black','BoxOpacity',1);
        im = insertText(im,[size(data,1) size(data,2)],num2str(lim(1)),'AnchorPoint','RightBottom',...
            'Font','Arial','FontSize',font_size,'TextColor','white','BoxColor','black','BoxOpacity',1);
    end
    
    if ~strcmp(options.t,'')
        im = insertText(im,[0,0],options.t,'AnchorPoint','LeftTop',...
            'Font','Arial','FontSize',font_size,'TextColor','white','BoxColor','black','BoxOpacity',1);
    end
    
    %{
    % Draw main image
    %=========================================
    im(1)=image(mapped_data,'Parent',h);    
    set(h,'XTick',[],'YTick',[]);
    
    daspect(h,[1 1 1]);
    
    set(h,'Units','pixels');
    pos=plotboxpos(h);
    set(h,'Units','normalized');
    
    % Draw colourbar and labels
    %=========================================
    if ~isempty(hc)
        im(2)=image(cbar,'Parent',hc);
        set(hc,'XTick',[],'YTick',[]);
    
        ht1=text(pos(3), 2, num2str(lim(1)), 'Units','pixels','Parent',h,...
             'Color','w','BackgroundColor','k','Margin',1,...
             'FontUnits','points','FontSize',10,...
             'HorizontalAlignment','right','VerticalAlignment','bottom');

        ht2=text(pos(3), pos(4)-1, num2str(lim(2)), 'Units','pixels','Parent',h,...
             'Color','w','BackgroundColor','k','Margin',1,...
             'FontUnits','points','FontSize',10,...
             'HorizontalAlignment','right','VerticalAlignment','top');

        set(ht1,'Units','normalized');
        set(ht2,'Units','normalized');

        bar_pos = [pos(1)+pos(3) pos(2) 20 pos(4)];
        set(hc,'Units','pixels','Position',bar_pos);
    
        set(hc,'Units','normalized');

    end
    
    
    % Draw text labels
    %=========================================
    if ~isempty(t) && ~strcmp(t,'')
        ht3=text(3, pos(4), t, 'Units','pixels','Parent',h,...
         'Color','w','BackgroundColor','k','Margin',1,...
         'FontUnits','points','FontSize',10,...
         'HorizontalAlignment','left','VerticalAlignment','top');
        set(ht3,'Units','normalized');
    end
    
    %}
    
end