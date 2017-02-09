classdef flex_roi < handle
   
    properties
       fig
       ax
       type 
       shape
       callback
       mask_size
       
       first_point
       points;
    end
    
    methods
        function obj = flex_roi(fig,ax,type,mask_size,callback)
            obj.fig = fig;
            obj.ax = ax;
            obj.type = type;
            obj.callback = callback;
            obj.mask_size = mask_size;
            
            if strcmp(obj.type,'poly')
                obj.shape = line(obj.ax,0,0,'Color','r','MarkerFaceColor','r',...
                              'LineWidth',2,'Marker','o');

            else
                obj.shape = patch(obj.ax,0,0,'r','EdgeColor','r','MarkerFaceColor','r',...
                              'FaceAlpha',0.5,'LineWidth',2);
            end


            switch obj.type
                case 'rect'
                    set(obj.fig, 'WindowButtonMotionFcn', @obj.mouseMoveRect);
                case 'ellipse'
                    set(obj.fig, 'WindowButtonMotionFcn', @obj.mouseMoveEllipse);
                case 'poly'
                    set(obj.fig, 'WindowButtonMotionFcn', @obj.mouseMovePoly);
            end
            
            set(obj.fig, 'WindowButtonDownFcn', @obj.mouseDown);
            set(obj.fig, 'WindowButtonUpFcn', @obj.mouseUp);
            set(obj.fig, 'Pointer','crosshair');
        end
        
        function mouseDown(obj,~,~)
            C = get(obj.ax, 'CurrentPoint');
            obj.first_point = C(1,1:2);
       end


        function mouseUp(obj,~,~)
             
            C = get(obj.ax, 'CurrentPoint');
            C = C(1,1:2);

            switch obj.type   
                case 'poly'
                    
                    if numel(obj.points) >= 2 && norm(C-obj.points(1,:)) < 5
                        obj.closeRoi();
                    else
                        obj.points = [obj.points; C];
                        set(obj.shape,'XData',obj.points(:,1),'YData',obj.points(:,2));                
                    end
                    
                case 'rect'
                    
                    [x,y] = obj.getRect(C);
                    obj.points = [x y];
                    obj.closeRoi();
                    
                case 'ellipse'
                    
                    [x,y] = obj.getEllipse(C);
                    obj.points = [x y];
                    obj.closeRoi();
                    
            end
        end
        
        function mouseMoveRect(obj,~,~)
            
            C = get(obj.ax, 'CurrentPoint');
            C = C(1,1:2);
            
            if ~isempty(obj.first_point)
                [x,y] = obj.getRect(C);
                set(obj.shape,'XData',x,'YData',y);
            end
            
        end
        
        
        function mouseMoveEllipse(obj,~,~)
            
            C = get(obj.ax, 'CurrentPoint');
            C = C(1,1:2);
            
            if ~isempty(obj.first_point)
                [x,y] = obj.getEllipse(C);
                set(obj.shape,'XData',x,'YData',y);
            end
            
        end
        
        function mouseMovePoly(obj,~,~)
            C = get(obj.ax, 'CurrentPoint');
            C = C(1,1:2);
            
            if ~isempty(obj.first_point)
                p = [obj.points;C];
                set(obj.shape,'XData',p(:,1),'YData',p(:,2));
            end        
        end
        
        function [x,y] = getRect(obj,C)
            x = [obj.first_point(1) obj.first_point(1) C(1) C(1) obj.first_point(1)]';
            y = [obj.first_point(2) C(2) C(2) obj.first_point(2) obj.first_point(2)]';
        end

        function [x,y] = getEllipse(obj,C)
            sz = C - obj.first_point;
            
            c = obj.first_point + 0.5 * sz;
            
            t = linspace(0,2*pi,50)';
            x = c(1) + 0.5 * sz(1) * sin(t);
            y = c(2) + 0.5 * sz(2) * cos(t);
                       
        end
                 
        
        function closeRoi(obj)
            [X,Y] = meshgrid(1:obj.mask_size(2),1:obj.mask_size(1));
            mask = inpolygon(X,Y,obj.points(:,1),obj.points(:,2));

            obj.cleanup();
            obj.callback(mask);
        end
        
        function cleanup(obj)
            set(obj.fig, 'WindowButtonMotionFcn', []);
            set(obj.fig, 'WindowButtonDownFcn', []);
            set(obj.fig, 'WindowButtonUpFcn', []);
            set(obj.fig, 'Pointer','arrow');
            delete(obj.shape);
        end
        
        function delete(obj)
            obj.cleanup();
        end

        
    end
    
end