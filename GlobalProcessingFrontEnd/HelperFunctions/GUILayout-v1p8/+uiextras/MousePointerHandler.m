classdef MousePointerHandler < handle
    %MousePointerHandler  A class to handle mouse-over events
    %
    %   MousePointerHandler(fig) attaches the handler to the figure FIG
    %   so that it will intercept all mouse-over events. The handler is
    %   stored in the MousePointerHandler app-data of the figure so that
    %   functions can listen in for scroll-events.
    %
    %   Examples:
    %   >> f = figure();
    %   >> u = uicontrol();
    %   >> mph = uiextras.MousePointerHandler(f);
    %   >> mph.register( u, 'fleur' )
    %
    %   See also: uiextras.ScrollWheelEvent
    
    %   Copyright 2008-2010 The MathWorks Ltd.
    %   $Revision: 288 $   
    %   $Date: 2010-07-14 12:23:50 +0100 (Wed, 14 Jul 2010) $
    
    properties( SetAccess = private, GetAccess = public )
        CurrentObject
    end % read-only public properties
    
    properties( SetAccess = private , GetAccess = private )
        CurrentObjectPosition
        OldPointer
        Parent
        List
    end % private properties
    
    methods
        
        function obj = MousePointerHandler(fig)
            % Check that a mouse-pointer-handler is not already there
            if ~isa( fig, 'figure' )
                fig = ancestor( fig, 'figure' );
            end
            if isappdata(fig,'MousePointerHandler')
                obj = getappdata(fig,'MousePointerHandler');
            else
                set(fig,'WindowButtonMotionFcn', @obj.onMouseMoved);
                setappdata(fig,'MousePointerHandler',obj);
                obj.Parent = fig;
            end
        end % MousePointerHandler
        
        function register( obj, widget, pointer )
            % We need to be sure to remove the entry if it dies
            if isHGUsingMATLABClasses()
                % New style
                l = event.listener( widget, 'ObjectBeingDestroyed', @obj.onWidgetBeingDestroyedEvent );
            else
                % Old school
                l = handle.listener( widget, 'ObjectBeingDestroyed', @obj.onWidgetBeingDestroyedEvent );
            end
            entry = struct( ...
                'Widget', widget, ...
                'Pointer', pointer, ...
                'Listener', l );
            if isempty(obj.List)
                obj.List = entry;
            else
                obj.List(end+1,1) = entry;
            end
        end % register
        
    end % public methods
    
    methods( Access = private )
        
        function onMouseMoved( obj, src, evt ) %#ok<INUSD>
            if isempty( obj.List )
                return;
            end
            currpos = get( obj.Parent, 'CurrentPoint' );
            if ~isempty( obj.CurrentObjectPosition )
                cop = obj.CurrentObjectPosition;
                if currpos(1) >= cop(1) ...
                        && currpos(1) < cop(1)+cop(3) ...
                        && currpos(2) >= cop(2) ...
                        && currpos(2) < cop(2)+cop(4)
                    % Still inside, so do nothing
                    return;
                else
                    % Left the object
                    obj.leaveWidget()
                end
            end
            % OK, now scan the objects to see if we're inside
            for ii=1:numel(obj.List)
                % We need to be careful of widgets that aren't capable of
                % returning a PixelPosition
                try
                    widgetpos = getpixelposition( obj.List(ii).Widget, true );
                    if currpos(1) >= widgetpos(1) ...
                            && currpos(1) < widgetpos(1)+widgetpos(3) ...
                            && currpos(2) >= widgetpos(2) ...
                            && currpos(2) < widgetpos(2)+widgetpos(4)
                        % Inside
                        obj.enterWidget( obj.List(ii).Widget, obj.List(ii).Pointer )
                        break; % we don't need to carry on looking
                    end
                catch err %#ok<NASGU>
                    warning( 'MousePointerHandler:BadWidget', 'GETPIXELPOSITION failed for widget %d', ii )
                end
            end
            
        end % onMouseMoved
        
        function onWidgetBeingDestroyedEvent( obj, src,evt ) %#ok<INUSD>
            idx = cellfun( @isequal, {obj.List.Widget}, repmat( {double(src)}, 1,numel(obj.List) ) );
            obj.List(idx) = [];
            % Also take care if it's the active object
            if isequal( src, obj.CurrentObject )
                obj.leaveWidget()
            end
        end % onWidgetBeingDestroyedEvent
        
        function enterWidget( obj, widget, pointer )
            % Mouse has moved onto a widget
            obj.CurrentObjectPosition = getpixelposition( widget );
            obj.CurrentObject = widget;
            obj.OldPointer = get( obj.Parent, 'Pointer' );
            set( obj.Parent, 'Pointer', pointer );
        end % enterWidget
        
        function leaveWidget( obj )
            % Mouse has moved off a widget
            obj.CurrentObjectPosition = [];
            obj.CurrentObject = [];
            set( obj.Parent, 'Pointer', obj.OldPointer );
        end % leaveWidget
        
    end % private methods
    
end % classdef