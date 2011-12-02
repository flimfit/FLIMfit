classdef Box < uiextras.Container
    %Box  Box base class
    %
    %   See also: uiextras.HBox
    %             uiextras.VBox
    
    %   Copyright 2009-2010 The MathWorks, Inc.
    %   $Revision: 301 $
    %   $Date: 2010-07-22 16:40:01 +0100 (Thu, 22 Jul 2010) $
    
    properties( SetObservable = true )
        
        Sizes = zeros( 1, 0 ) % vector of sizes, with positive elements for absolute sizes (pixels) and negative elements for relative sizes
        Padding = 0 % padding around contents (pixels)
        Spacing = 0 % spacing between contents (pixels)
        
    end % public properties
    
    methods
        
        function obj = Box( varargin )
            %BOX  Container with contents in a single row or column
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj@uiextras.Container( varargin{:} );
            
            % Set some defaults
            obj.setPropertyFromDefault( 'Padding' );
            obj.setPropertyFromDefault( 'Spacing' );
            
        end % constructor
        
        function set.Sizes( obj, value )
            % Check. We only count live children
            myChildren = obj.getValidChildren();
            if ~isequal( numel( myChildren ), numel( value ) )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Size of property ''Sizes'' must match size of property ''Children''.' )
            elseif ~isnumeric( value ) || ...
                    any( ~isreal( value ) ) || any( isnan( value ) ) || any( ~isfinite( value ) )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''Sizes'' must consist of real, finite, numeric values.' )
            end
            
            % Set
            obj.Sizes = value(:)';
            
            % Redraw
            obj.redraw();
        end % set.Sizes
        
        function set.Padding( obj, value )
            % Check
            if ~isnumeric( value ) || ~isscalar( value ) || ...
                    ~isreal( value ) || isnan( value ) || ~isfinite( value ) || ...
                    value < 0 || rem( value, 1 ) ~= 0
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''Padding'' must be a nonnegative integer.' )
            end
            
            % Set
            obj.Padding = value;
            
            % Redraw
            obj.redraw();
        end % set.Padding
        
        function set.Spacing( obj, value )
            % Check
            if ~isnumeric( value ) || ~isscalar( value ) || ...
                    ~isreal( value ) || isnan( value ) || ~isfinite( value ) || ...
                    value < 0 || rem( value, 1 ) ~= 0
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''Spacing'' must be a nonnegative integer.' )
            end
            
            % Set
            obj.Spacing = value;
            
            % Redraw
            obj.redraw();
        end % set.Spacing
        
    end % public methods
    
    methods( Access = protected )
        
        function pixsizes = calculatePixelSizes( obj, availableSize )
            children = obj.getValidChildren();
            nChildren = numel( children );
            padding = obj.Padding;
            spacing = obj.Spacing;
            sizes = obj.Sizes;
            
            pixsizes = zeros( size( children ) ); % initialize
            
            % First set the fixed-size components
            fixed = ( sizes >= 0 );
            pixsizes(fixed) = sizes(fixed);
            
            % Now split the remaining space between any flexible ones
            flexible = ( sizes<0 );
            availableSize = availableSize ...
                - sum( sizes(fixed) ) ...     % space taken by fixed components
                - spacing * (nChildren-1) ... % space taken by the spacing
                - padding * 2;                % space around the edge
            pixsizes(flexible) = sizes(flexible) / sum( sizes(flexible) ) * availableSize;
            
            % Minimum is 1 pixel
            pixsizes = max( pixsizes, 1 );
        end % calculatePixelSizes
        
        function onChildAdded( obj, source, eventData ) %#ok<INUSD>
            % This callback fires when a child is added to a container.
            % Add an element to Sizes.  This automatically triggers a
            % redraw.
            obj.Sizes(1,end+1) = -1;
        end % onChildAdded
        
        function onChildRemoved( obj, source, eventData ) %#ok<INUSL>
            % This callback fires when a child is destroyed or removed.
            % Work out which child has gone and delete the corresponding
            % element from Sizes.  This automatically triggers a redraw.
            obj.Sizes( eventData.ChildIndex ) = [];
        end % onChildRemoved
        
    end % protected methods
    
end % classdef