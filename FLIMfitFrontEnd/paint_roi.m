classdef paint_roi < handle
   
    properties
       fig
       ax
       paint_im
       mask_size
       brush_width
       
       callback
       
       paint_mask
       last_pos
       mouse_down
       X
       Y
    end
    
    methods
        function obj = paint_roi(fig,ax,brush_width,mask_size,callback)
            obj.fig = fig;
            obj.ax = ax;
            obj.brush_width = brush_width;
            obj.mask_size = mask_size;
            obj.callback = callback;
  
            [obj.X,obj.Y] = meshgrid(1:mask_size(2),1:mask_size(1));

            hold(ax,'on');
            paint = repmat(reshape([1 0 0],[1 1 3]),[mask_size 1]);
            obj.paint_mask = zeros(mask_size,'logical');
            obj.paint_im = image(paint,'AlphaData',zeros(mask_size));            
            hold(ax,'off');
            
            set(obj.fig, 'WindowButtonMotionFcn', @obj.MouseMove);
            set(obj.fig, 'WindowButtonDownFcn', @obj.MouseDown);
            set(obj.fig, 'WindowButtonUpFcn', @obj.MouseUp);
        end
        
        function MouseDown(obj,~,~)
            obj.mouse_down = true;
            obj.last_pos = [];
        end

        function MouseUp(obj,~,~)
            obj.cleanup();
            obj.callback(obj.paint_mask);
        end

        function MouseMove(obj,~,~)

            if obj.mouse_down

                r = obj.brush_width;

                C = get(obj.ax, 'CurrentPoint');
                pos = [C(1,1), mod(C(1,2), size(obj.paint_mask,1)) + 1];

                all_pos = pos;
                if ~isempty(obj.last_pos)
                    distance = norm(obj.last_pos-pos);
                    n = ceil(distance / r) * 2;

                    all_pos = [linspace(obj.last_pos(1),pos(1),n)' linspace(obj.last_pos(2),pos(2),n)'];
                end

                obj.last_pos = pos;

                for i=1:size(all_pos,1)
                    sel = (obj.Y-all_pos(i,2)).^2 + (obj.X-all_pos(i,1)).^2 < r^2;
                    obj.paint_mask(sel) = 1;
                end

                set(obj.paint_im,'AlphaData', obj.paint_mask * 0.5);
            end
        end
        
        function cleanup(obj)
            set(obj.fig, 'WindowButtonMotionFcn', []);
            set(obj.fig, 'WindowButtonDownFcn', []);
            set(obj.fig, 'WindowButtonUpFcn', []);
            set(obj.fig, 'Pointer','arrow');
            delete(obj.paint_im);
        end
        
        function delete(obj)
            obj.cleanup();
        end
        
    end
    
end