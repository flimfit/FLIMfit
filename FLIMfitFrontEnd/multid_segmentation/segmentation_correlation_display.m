classdef segmentation_correlation_display < handle
    
    properties
       parent;
       controller; 
       
       panel;
       ax;
       im;
       
       mask;
       
       x_listbox;
       y_listbox;
       
       x_data;
       y_data;
       
       tool_roi_circle_toggle;
       tool_roi_rect_toggle; 
       tool_roi_poly_toggle;
       toggle_active;
       flex_h;
    end
        
    methods
       
        function obj = segmentation_correlation_display(controller,parent)
            obj.parent = parent;
            obj.controller = controller;
            
            obj.setup_layout();
            obj.update();
        end
        
        function setup_layout(obj)
            
            labels = fieldnames(obj.controller.dataset);
            
            obj.panel = uipanel('Parent',obj.parent);
            display_layout = uix.VBox('Parent',obj.panel);
            obj.ax = axes('Parent',display_layout);
            set(obj.ax,'Units','normalized','Position',[0 0 1 1]);

            control_layout = uix.HBox('Parent',display_layout);
            
            icons = load('icons.mat');
            obj.tool_roi_rect_toggle = uicontrol(control_layout,'Style','togglebutton','CData',icons.rect_icon,'ToolTipString','Rectangle','Callback',@obj.toggle_callback);
            obj.tool_roi_poly_toggle = uicontrol(control_layout,'Style','togglebutton','CData',icons.poly_icon,'ToolTipString','Polygon','Callback',@obj.toggle_callback);
            obj.tool_roi_circle_toggle = uicontrol(control_layout,'Style','togglebutton','CData',icons.ellipse_icon,'ToolTipString','Ellipse','Callback',@obj.toggle_callback);  
            
            uicontrol(control_layout,'Style','text','String','X');
            obj.x_listbox = uicontrol(control_layout,'Style','popupmenu','String',labels,'Callback',@obj.update);
            uicontrol(control_layout,'Style','text','String','Y');
            obj.y_listbox = uicontrol(control_layout,'Style','popupmenu','String',labels,'Value',2,'Callback',@obj.update);
            uicontrol(control_layout,'Style','pushbutton','String','-','Callback',@obj.remove);
            uicontrol(control_layout,'Style','pushbutton','String','+','Callback',@obj.add);
            control_layout.Widths = [30 30 30 30 -1 30 -1 30 30];
            display_layout.Heights = [-1 22];

            obj.im = image(0,'Parent',obj.ax);            
            edges = linspace(0,1,256);
            ed = edges(2:255);
            obj.im = imagesc(ed,ed,ones(256,256),'Parent',obj.ax);
            daspect(obj.ax,[1 1 1])
            set(obj.ax,'YDir','normal','XTick',[],'YTick',[]);

            %{
            hold(obj.phasor_axes,'on');
            theta = linspace(0,pi,1000);
            c = 0.5*(cos(theta) + 1i * sin(theta)) + 0.5;
            plot(obj.phasor_axes,real(c), imag(c) ,'w');
            %}
            
            n_panel = length(obj.parent.Children);
            n_x = ceil(sqrt(n_panel));
            n_y = ceil(n_panel / n_x);
            obj.parent.Heights = -1 * ones(1,n_x);
            obj.parent.Widths = -1 * ones(n_y,1);
            
        end 
        
        function update(obj,~,~)
            
            x_name = obj.x_listbox.String{obj.x_listbox.Value};
            y_name = obj.x_listbox.String{obj.y_listbox.Value};
            
            obj.x_data = obj.controller.dataset.(x_name);
            obj.y_data = obj.controller.dataset.(y_name);
            
            x_max = 1;
            y_max = 1;
            
            if ~any(strcmp(x_name,{'p_r','p_i'}))
                x_max = prctile(obj.x_data(:),99.9);
            end
            if ~any(strcmp(y_name,{'p_r','p_i'}))
                y_max = prctile(obj.y_data(:),99.9);
            end
            
            obj.x_data = obj.x_data / x_max;
            obj.y_data = obj.y_data / y_max;
            
            obj.x_data(obj.x_data>1) = 1;
            obj.y_data(obj.y_data>1) = 1;
            
            I = ones(size(obj.x_data));

            pc = [obj.y_data(:) obj.x_data(:)];        
            n = histwv2(pc,I(:),0,1,256);
            n = n(2:255,2:255);
            %n(:,:,i) = ni; % / prctile(ni(:),99.9);

            %n = flip(n,3); % BGR -> RGB

            n = n / prctile(n(:),99.9);
            n(n>1) = 1;
            set(obj.im,'CData',n);
            
        end
        
        function toggle_callback(obj,src,~)
            toggles = [obj.tool_roi_rect_toggle 
               obj.tool_roi_poly_toggle
               obj.tool_roi_circle_toggle];
            toggle_fcn = {@imrect,@impoly,@imellipse};

            if src.Value == 1
                set(toggles(toggles ~= src),'Value',0);

                toggle_fcn = toggle_fcn{toggles == src};
                obj.flex_h = toggle_fcn(obj.ax);
                obj.flex_h.addNewPositionCallback(@obj.roi_callback);
                obj.flex_h.setResizable(true);
                obj.toggle_active = src;
            else
                if obj.toggle_active == src && ~isempty(obj.flex_h)
                    delete(obj.flex_h)
                end
            end            
        end
        
        function roi_callback(obj,src,evt)
            modifier = get(gcbf,'currentmodifier');
                        
            if ~isempty(obj.flex_h) 
               pos = obj.flex_h.getPosition();
               sel = zeros(size(obj.x_data));
               if isa(obj.flex_h,'imrect')
                   sel = obj.x_data >= pos(1) & obj.x_data <= (pos(1) + pos(3)) & ...
                         obj.y_data >= pos(2) & obj.y_data <= (pos(2) + pos(4));
               end
               
               obj.mask = sel;
            end
            
            obj.controller.update_display();
            
        end
        
        function add(obj,~,~)
            obj.controller.add_correlation();
        end
        
        function remove(obj,~,~)
            delete(obj.panel);
            delete(obj);
        end
        
    end
    
end