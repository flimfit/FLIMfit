
function txt = interactive_plot_update(~,event_obj,obj,y_scatter,f_scatter,grouping,x_data,hs)
    %TODO - expand for arbitrary metadata parameters
    %TODO - think of sensible way to handle regions
    %TODO - turn on and off using contextmenu
    
    try
        pos = get(event_obj,'Position');
        T = get(event_obj,'Target');
%         hs

        if T == hs
            md = obj.fit_controller.fit_result.metadata;

            if grouping == 1 || grouping == 3
                FOV = f_scatter(y_scatter == pos(2));
                Well = md.Well(FOV{1} == [f_scatter{:}]);
                txt = {[obj.ind_param  ': ' x_data{pos(1)}],...
                    [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' num2str(pos(2))],...
                    ['Well: ' Well{:}],...
                    ['FOV:' num2str(FOV{:})],...
%                     ['Target: ' num2str(T)]};
                };
            elseif grouping == 4
                Well = f_scatter{y_scatter == pos(2)};
                txt = {[obj.ind_param ': ', num2str(pos(1))],...
                    [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' num2str(pos(2))],...
                    ['Well: ' Well],...
%                     ['Target: ' num2str(T)]};
                };
            end
        else    
            txt = {['Mean ' obj.ind_param  ': ' x_data{pos(1)}], ...
                [obj.fit_controller.fit_result.latex_params{obj.cur_param} ': ' num2str(pos(2))]};
        end
    catch err
        txt = {['Error in generating datapoint:  ' err]};
    end

end