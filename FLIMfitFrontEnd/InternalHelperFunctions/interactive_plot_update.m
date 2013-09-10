function txt = interactive_plot_update(~,event_obj,obj,y_scatter,f_scatter,r_scatter,grouping,x_data,hs)
    
%     try
        pos = get(event_obj,'Position');
        T = get(event_obj,'Target');
        
        dcm_obj = datacursormode(obj.window);
        dtip = dcm_obj.CurrentDataCursor;
        set(dtip,'Marker','o','MarkerFaceColor','none','MarkerEdgeColor','g');

        if iscell(x_data)
            x = x_data{pos(1)};
        else
            x = num2str((x_data(x_data == pos(1))));
        end
            
        
        if T == hs
            md = obj.fit_controller.fit_result.metadata;
            
            if grouping == 2
                Region = r_scatter(y_scatter == pos(2));
                FOV = f_scatter(y_scatter == pos(2));
                Well = md.Well(FOV{1} == [md.FOV{:}]);
                txt = {[obj.ind_param  ': '  x],...
                    [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' sprintf('%6.0f',pos(2))],...
                    ['Well: ' Well{:}],...
                    ['FOV: ' num2str(FOV{:})],...
                    ['Region: ' num2str(Region)],...
%                     ['Target: ' num2str(T)]};
                };
            elseif grouping == 1 || grouping == 3
                FOV = f_scatter(y_scatter == pos(2));
                Well = md.Well(FOV == [md.FOV{:}]);
                txt = {[obj.ind_param  ': ' x],...
                    [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' sprintf('%6.0f',pos(2))],...
                    ['Well: ' Well{:}],...
                    ['FOV:' num2str(FOV)],...
%                     ['Target: ' num2str(T)]};
                };
            elseif grouping == 4
                Well = f_scatter{y_scatter == pos(2)};
                txt = {[obj.ind_param ': ', x],...
                    [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' sprintf('%6.0f',pos(2))],...
                    ['Well: ' Well],...
%                     ['Target: ' num2str(T)]};
                };
            end
        else    
            txt = {['Mean ' obj.ind_param  ': ' x], ...
                [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' sprintf('%6.0f',pos(2))]};
        end
%     catch err
%         txt = {['Error in generating datapoint:  ' err]};
%     end

end

