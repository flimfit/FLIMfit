classdef flim_fit_platemap_controller < abstract_plot_controller
    
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

   
    properties
       colorbar_axes; 
    end
    
    methods
        function obj = flim_fit_platemap_controller(handles)
                       
            obj = obj@abstract_plot_controller(handles,handles.plate_axes,handles.plate_param_popupmenu,true);            
            assign_handles(obj,handles);

            obj.update_display();
        end
        
        function draw_plot(obj,ax,param)

            create_im_plate = false;
            
            plate_size = 0;
            
            n_col = 12*2^plate_size;
            n_row = 8*2^plate_size;
            
            row_headers = (1:n_row)+64;
            row_headers = char(row_headers);
            row_headers = cellstr(row_headers');
            
            col_headers = 1:n_col;
            col_headers = num2str(col_headers');
            col_headers = cellstr(col_headers)';
            
            if obj.fit_controller.has_fit && param>0

                r = obj.fit_controller.fit_result;  
                f = obj.fit_controller;
                sel = obj.fit_controller.selected;

                md = r.metadata;

                if ~isfield(md,'Row') || ~isfield(md,'Column')
                    set(ax,'XTick',[],'YTick',[],'Box','on');
                    return
                end

                im_row = md.Row(sel);
                im_col = md.Column(sel);
                
                for i=1:length(im_col)
                    if isempty(im_col{i})
                        im_col{i} = '0';
                    end
                end
                
                for i=1:length(im_row)
                    if isempty(im_row{i})
                        im_row{i} = 'X';
                    end
                end


                plate = zeros(n_row,n_col) * NaN;
                
                if create_im_plate
                     gw = r.width * n_col; gh = r.height * n_row;
                     im_plate = NaN([gh gw]);
                end
               
                for row_idx = 1:n_row
                    row = char(row_idx+64);
                    for col = 1:n_col

                        sel_well = strcmp(im_row,row) & cell2mat(im_col)==col;
                        sel_well = sel(sel_well);

                        y = 0;
                        yn = 0;

                        if create_im_plate && ~isempty(sel_well)
                            ci = (col-1)*r.width+1;
                            ri = (row_idx-1)*r.height+1;
                            
                            im_plate(ri:ri+r.height-1,ci:ci+r.width-1) = f.get_image(sel_well(1),param);         
                        end
                            
                        for i=sel_well

                            n = r.image_size{i};
                            if n > 0
                                y = y + r.image_stats{i}.mean(param) * n; 
                                yn = yn + n;
                            end
                                
                        end
                        
                        plate(row_idx,col) = y/yn;

                    end
                end

                lims = f.get_cur_lims(param);
                cscale = obj.colourscale(param);
                

                set(ax,'Units','pixels');
                pos=plotboxpos(ax);
                bar_pos = [pos(1)+pos(3) pos(2) 20 pos(4)];
                
                parent = get(ax,'Parent');
                if isempty(obj.colorbar_axes) || ax ~= obj.plot_handle
                	ca = axes('Units','pixels','Position',bar_pos,'YTick',[],'XTick',[],'Box','on','Parent',parent);
                    if isempty(obj.colorbar_axes)
                        obj.colorbar_axes = ca;
                    end
                else
                    ca = obj.colorbar_axes;
                end
               
                if create_im_plate
                    im = colorbar_flush(ax,ca,im_plate,isnan(im_plate),lims,cscale);
                    w = r.width;
                    h = r.height;
                    c = 'w';
                    f = 0.5;
                else
                    im = colorbar_flush(ax,ca,plate,[],lims,cscale);
                    w = 1;
                    h = 1;
                    c = 'k';
                    f = 0;
                end
                
                daspect(ax,[ 1 1 1 ])
               
                for i=1:n_col
                    line([i i]*w+0.5,[0 n_row]*h+0.5,'Parent',ax,'Color',c);
                end
                for i=1:n_row
                    line([0 n_col]*w+0.5,[i i]*h+0.5,'Parent',ax,'Color',c);
                end

                if ( ax == obj.plot_handle )
                    set(im,'uicontextmenu',obj.contextmenu);
                end
                
                obj.raw_data = [row_headers num2cell(plate)];
                obj.raw_data = [r.params{param} num2cell(1:n_col); obj.raw_data];
                
                set(ax,'YTick',(1:1:n_row)*h-h*f);
                set(ax,'YTickLabel',row_headers);
                set(ax,'XTick',(1:n_col)*w-w*f);
                set(ax,'XTickLabel',col_headers);
                set(ax,'TickLength',[0 0]);
            else
                im=image(zeros([n_row n_col]),'Parent',ax);
                set(ax,'YTickLabel',row_headers);
                set(ax,'XTick',0:1:n_col);
                set(ax,'TickLength',[0 0]);
                daspect(ax,[1 1 1]);
                set(im,'uicontextmenu',obj.contextmenu);
                w = 1;
                h = 1;
                f = 1;
            end
            
            
            

            

            
        end


        
    end
    
    
end