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

            n_col = 12;
            n_row = 8;
            
            row_headers = {'A'; 'B'; 'C'; 'D'; 'E'; 'F'; 'G'; 'H'};


            if obj.fit_controller.has_fit

                r = obj.fit_controller.fit_result;     

                md = r.metadata;

                if ~isfield(md,'Row') || ~isfield(md,'Column')
                    set(ax,'XTick',[],'YTick',[],'Box','on');
                    return
                end

                im_row = md.Row;
                im_col = md.Column;

                plate = zeros(n_row,n_col) * NaN;

                for row_idx = 1:n_row
                    row = char(row_idx+64);
                    for col = 1:n_col

                        sel = strcmp(im_row,row) & cell2mat(im_col)==col;
                        idx = 1:length(im_row);
                        sel = idx(sel);

                        y=[];

                        for i=1:length(sel)

                            if isfield(r.image_stats{sel(i)},param)
                                y(end+1) = r.image_stats{sel(i)}.(param).mean;
                            end
                        end

                        plate(row_idx,col) = nanmean(y);

                    end
                end

                lims = r.default_lims.(param);
                cscale = obj.colourscale(param);
                

                set(ax,'Units','pixels');
                pos=plotboxpos(ax);
                bar_pos = [pos(1)+pos(3) pos(2) 20 pos(4)];
                
                parent = get(ax,'Parent');
                if isempty(obj.colorbar_axes) || ax ~= obj.plot_handle
                	obj.colorbar_axes = axes('Units','pixels','Position',bar_pos,'YTick',[],'XTick',[],'Box','on','Parent',parent);
                else
                    set(obj.colorbar_axes,'Units','pixels','Position',bar_pos);
                end
               
                
                im = colorbar_flush(ax,obj.colorbar_axes,plate,[],lims,cscale);
                daspect(ax,[ 1 1 1 ])
                %imagesc(mapped_plate,'Parent',ax);
                
                for i=1:n_col
                    line([i+.5 i+.5],[0.5 n_row+.5],'Parent',ax,'Color','k');
                end
                for i=1:n_row
                    line([0.5 n_col+.5],[i+.5 i+.5],'Parent',ax,'Color','k');
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

            end
            
            
            
            set(ax,'YTick',1:1:n_row);
            set(ax,'YTickLabel',row_headers);
            set(ax,'XTick',1:n_col);
            set(ax,'TickLength',[0 0]);
            

            
        end


        
    end
    
    
end