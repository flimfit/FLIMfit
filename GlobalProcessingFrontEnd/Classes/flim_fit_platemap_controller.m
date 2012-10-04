classdef flim_fit_platemap_controller < abstract_plot_controller
   
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

            create_im_plate = true;
            
            n_col = 12;
            n_row = 8;
            
            row_headers = {'A'; 'B'; 'C'; 'D'; 'E'; 'F'; 'G'; 'H'};
            col_headers = {'1';'2';'3';'4';'5';'6';'7';'8';'9';'10';'11';'12'};

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
                            
                            im_plate(ri:ri+r.height-1,ci:ci+r.width-1) = r.get_image(sel_well(1),param);         
                        end
                            
                        for i=sel_well

                            n = r.image_size{i};
                            if n > 0
                                y = y + r.image_mean{i}(param) * n; 
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
                obj.raw_data = [{param} num2cell(1:n_col); obj.raw_data];
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
            
            
            
            set(ax,'YTick',(1:1:n_row)*h-h*f);
            set(ax,'YTickLabel',row_headers);
            set(ax,'XTick',(1:n_col)*w-w*f);
            set(ax,'XTickLabel',col_headers);
            set(ax,'TickLength',[0 0]);
            

            
        end


        
    end
    
    
end