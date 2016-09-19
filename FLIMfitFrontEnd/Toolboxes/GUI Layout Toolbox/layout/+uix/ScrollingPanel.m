classdef ScrollingPanel < uix.Container & uix.mixin.Panel
    %uix.ScrollingPanel  Scrolling panel
    %
    %  b = uix.ScrollingPanel(p1,v1,p2,v2,...) constructs a scrolling panel
    %  and sets parameter p1 to value v1, etc.
    %
    %  A scrolling panel is a standard container (uicontainer) that shows
    %  one its contents and hides the others, and allows the user to page
    %  through the contents using a slider.
    %
    %  See also: uix.Panel, uix.CardPanel, uix.BoxPanel, uix.TabPanel,
    %  uicontainer
    
    %  Copyright 2016 The MathWorks, Inc.
    %  $Revision: 1165 $ $Date: 2015-12-06 03:09:17 -0500 (Sun, 06 Dec 2015) $
    
    properties( Access = public, Dependent, AbortSet )
        Orientation % orientation [vertical|horizontal]
    end
    
    properties( Access = protected )
        Slider % slider
        Orientation_ = 'vertical' % backing for Orientation
    end
    
    properties( Constant, Access = protected )
        SliderSize = 20 % slider size [pixels]
    end
    
    methods
        
        function obj = ScrollingPanel( varargin )
            %uix.ScrollingPanel  Scrolling panel constructor
            %
            %  p = uix.ScrollingPanel() constructs a scrolling panel.
            %
            %  p = uix.ScrollingPanel(p1,v1,p2,v2,...) sets parameter p1 to
            %  value v1, etc.
            
            % Create slider
            slider = uicontrol( 'Internal', true, 'Parent', obj, ...
                'Style', 'slider', 'Min', 0, 'Max', 1, ...
                'TooltipString', 'Slide to page through contents', ...
                'Callback', @obj.onSliderClicked );
            
            % Store properties
            obj.Slider = slider;
            
            % Set properties
            if nargin > 0
                uix.pvchk( varargin )
                set( obj, varargin{:} )
            end
            
        end % constructor
        
    end % structors
    
    methods
        
        function value = get.Orientation( obj )
            
            value = obj.Orientation_;
            
        end % get.Orientation
        
        function set.Orientation( obj, value )
            
            % Check
            assert( ischar( value ) && ismember( value, ...
                {'horizontal','vertical'} ) )
            
            % Set
            obj.Orientation_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.Orientation
        
    end % accessors
    
    methods( Access = protected )
        
        function redraw( obj )
            %redraw  Redraw
            %
            %  p.redraw() redraws the panel.
            %
            %  See also: redrawSlider
            
            % Count contents
            n = numel( obj.Contents_ );
            
            % Compute positions
            bounds = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            padding = obj.Padding_;
            switch obj.Orientation_
                case 'vertical'
                    w = (n>1) * obj.SliderSize;
                    xSizes = uix.calcPixelSizes( bounds(3)-w, -1, 1, padding, 0 );
                    ySizes = uix.calcPixelSizes( bounds(4), -1, 1, padding, 0 );
                    contentsPosition = [padding+1, padding+1, xSizes, ySizes];
                    sliderPosition = [bounds(3)-w+1, 1, w, bounds(4)];
                otherwise % horizontal
                    h = (n>1) * obj.SliderSize;
                    xSizes = uix.calcPixelSizes( bounds(3), -1, 1, padding, 0 );
                    ySizes = uix.calcPixelSizes( bounds(4)-h, -1, 1, padding, 0 );
                    contentsPosition = [padding+1, h+padding+1, xSizes, ySizes];
                    sliderPosition = [1, 1, bounds(3), h];
            end
            
            % Redraw contents
            obj.redrawContents( contentsPosition )
            
            % Redraw slider
            slider = obj.Slider;
            if numel( obj.Contents_ ) <= 1 % hide
                slider.Visible = 'off';
            else % show
                slider.Visible = 'on';
                slider.Position = sliderPosition;
                slider.Max = 1 - 1/n;
                slider.SliderStep = [1 1]/(n-1);
                slider.Value = 1 - obj.Selection_/n;
            end
            
        end % redraw
        
    end % template methods
    
    methods( Access = protected )
        
        function onSliderClicked( obj, ~, ~ )
            %onSliderClicked  Event handler
            
            % Update selection
            n = numel( obj.Contents_ );
            obj.Selection_ = round( n*(1-obj.Slider.Value) );
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % onSliderClicked
        
    end % event handlers
    
end % classdef