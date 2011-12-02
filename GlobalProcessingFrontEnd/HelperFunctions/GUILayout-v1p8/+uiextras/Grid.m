classdef Grid < uiextras.Container
    %Grid  Container with contents arranged in a grid
    %
    %   obj = uiextras.Grid() creates a new new grid layout with all
    %   properties set to defaults. The number of rows and columns to use
    %   is determined from the number of elements in the RowSizes and
    %   ColumnSizes properties respectively. Child elements are arranged
    %   down column one first, then column two etc. If there are
    %   insufficient columns then a new one is added. The output is a new
    %   layout object that can be used as the parent for other
    %   user-interface components. The output is a new layout object that
    %   can be used as the parent for other user-interface components.
    %
    %   obj = uiextras.Grid(param,value,...) also sets one or more
    %   parameter values.
    %
    %   See the <a href="matlab:doc uiextras.Grid">documentation</a> for more detail and the list of properties.
    %
    %   Examples:
    %   >> f = figure();
    %   >> g = uiextras.Grid( 'Parent', f, 'Spacing', 5 );
    %   >> uicontrol( 'Style', 'frame', 'Parent', g, 'Background', 'r' )
    %   >> uicontrol( 'Style', 'frame', 'Parent', g, 'Background', 'b' )
    %   >> uicontrol( 'Style', 'frame', 'Parent', g, 'Background', 'g' )
    %   >> uiextras.Empty( 'Parent', g )
    %   >> uicontrol( 'Style', 'frame', 'Parent', g, 'Background', 'c' )
    %   >> uicontrol( 'Style', 'frame', 'Parent', g, 'Background', 'y' )
    %   >> set( g, 'ColumnSizes', [-1 100 -2], 'RowSizes', [-1 100] );
    %
    %   See also: uiextras.GridFlex
    
    %   Copyright 2009-2010 The MathWorks, Inc.
    %   $Revision: 288 $ 
    %   $Date: 2010-07-14 12:23:50 +0100 (Wed, 14 Jul 2010) $
    
    properties( SetObservable = true ) 
        Padding = 0 % padding around and between contents [pixels]
        Spacing = 0 % spacing between contents [pixels]
    end % public properties
    
    properties( Dependent = true )
        RowSizes    % column vector of row sizes, with positive elements for absolute sizes (pixels) and negative elements for relative sizes
        ColumnSizes % column vector of column sizes, with positive elements for absolute sizes (pixels) and negative elements for relative sizes
    end % dependent properties
    
    properties( SetAccess = private, GetAccess = private )
        RowSizes_ = zeros( 0, 1 )    % private property for storing actual row sizes
        ColumnSizes_ = zeros( 0, 1 ) % private property for storing actual column sizes
    end % private properties
    
    methods
        
        function obj = Grid( varargin )
            %Grid  Create a container with contents in a grid.
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj@uiextras.Container( varargin{:} );

            % Set some defaults
            obj.setPropertyFromDefault( 'Padding' );
            obj.setPropertyFromDefault( 'Spacing' );

            % Set user-supplied property values (only if this is the leaf class)
            if nargin>0 && isequal( class( obj ), 'uiextras.Grid' )
                set( obj, varargin{:} );
            end
            
        end % constructor
        
    end % public methods
    
    methods
        
        function set.RowSizes( obj, value )
            
            % Check
            if ~isvector( value )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''RowSizes'' must be a vector.' )
            elseif ~isnumeric( value ) || ...
                    any( ~isreal( value ) ) || any( isnan( value ) ) || any( ~isfinite( value ) )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''RowSizes'' must consist of real, finite, numeric values.' )
            end
            
            % Set
            obj.RowSizes_ = value(:);
            
            % Add/remove elements to/from ColumnSizes, if required
            nColumns = ceil( numel( obj.Children ) / numel( obj.RowSizes_ ) );
            if numel( obj.ColumnSizes_ ) > nColumns
                obj.ColumnSizes_(nColumns+1:end,:) = [];
            elseif numel( obj.ColumnSizes ) < nColumns
                obj.ColumnSizes_(end+1:nColumns,1) = -1;
            end
            
            % Redraw
            obj.redraw();
            
        end % set.RowSizes
        
        function value = get.RowSizes( obj )
            value = obj.RowSizes_;
        end % get.RowSizes
        
        function set.ColumnSizes( obj, value )
            % Check
            if ~isvector( value )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''ColumnSizes'' must be a vector.' )
            elseif ~isnumeric( value ) || ...
                    any( ~isreal( value ) ) || any( isnan( value ) ) || any( ~isfinite( value ) )
                error( 'GUILayout:InvalidPropertyValue', ...
                    'Property ''ColumnSizes'' must consist of real, finite, numeric values.' )
            end
            
            % Set
            obj.ColumnSizes_ = value(:);
            
            % Add/remove elements to/from RowSizes, if required
            nRows = ceil( numel( obj.Children ) / numel( obj.ColumnSizes_ ) );
            if numel( obj.RowSizes_ ) > nRows
                obj.RowSizes_(nRows+1:end,:) = [];
            elseif numel( obj.RowSizes ) < nRows
                obj.RowSizes_(end+1:nRows,1) = -1;
            end
            
            % Redraw
            obj.redraw();
        end % set.ColumnSizes
        
        function value = get.ColumnSizes( obj )
            value = obj.ColumnSizes_;
        end % get.ColumnSizes
        
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
        
    end % accessor methods
    
    methods( Access = protected )
        
        function [widths,heights] = redraw( obj )
            %REDRAW  Redraw container contents.
            
            % Get container width and height
            totalPosition = ceil( getpixelposition( obj.UIContainer ) );
            totalWidth = totalPosition(3);
            totalHeight = totalPosition(4);
            
            % Get children
            children = obj.Children;
            nChildren = numel( children );
            
            % Get padding, spacing, widths and heights
            padding = obj.Padding;
            spacing = obj.Spacing;
            columnSizes = obj.ColumnSizes;
            nColumns = numel( columnSizes );
            rowSizes = obj.RowSizes;
            nRows = numel( rowSizes );
            
            % Compute widths and heights
            widths = calculatePixelSizes( obj, totalWidth, columnSizes );
            heights = calculatePixelSizes( obj, totalHeight, rowSizes );
            
            % Compute and set new positions in pixels
            elementNumbers = reshape( 1:nRows*nColumns, [nRows, nColumns] );
            rowNumbers = repmat( transpose( 1:nRows ), [1, nColumns] );
            columnNumbers = repmat( 1:nColumns, [nRows, 1] );
            for ii = 1:nChildren
                child = children(ii);
                jj = rowNumbers(elementNumbers==ii); % row index
                kk = columnNumbers(elementNumbers==ii); % column index
                x = sum( widths(1:kk-1) ) + padding + spacing * (kk-1) + 1;
                y = totalHeight - sum( heights(1:jj) ) - padding - spacing*(jj-1) + 1;
                newPosition = [x, y, widths(kk), heights(jj)];   
                obj.repositionChild( child, newPosition );
            end
            
        end % redraw
        
        function pixsizes = calculatePixelSizes( obj, availableSize, sizes )
            nChildren = numel( sizes );
            padding = obj.Padding;
            spacing = obj.Spacing;
            
            pixsizes = zeros( size( sizes ) ); % initialize
            
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
            %onChildAdded: Callback that fires when a child is added to a container.
            % Add element to RowSizes, if required
            if numel( obj.RowSizes_ ) == 0
                obj.RowSizes_ = -1;
            end
            
            % Add element to ColumnSizes, if required
            nColumns = ceil( numel( obj.Children ) / numel( obj.RowSizes_ ) );
            if numel( obj.ColumnSizes_ ) < nColumns
                obj.ColumnSizes_(end+1:nColumns,:) = -1;
            end
            
            obj.redraw();
            
        end % onChildAdded
        
        function onChildRemoved( obj, source, eventData ) %#ok<INUSD>
            %onChildAdded: Callback that fires when a container child is destroyed or reparented.
            if numel( obj.Children ) == 0
                % Remove elements from RowSizes and ColumnSizes
                obj.RowSizes_ = zeros( 0, 1 );
                obj.ColumnSizes_ = zeros( 0, 1 );
            else
                % Remove elements from ColumnSizes, if required
                nColumns = ceil( numel( obj.Children ) / numel( obj.RowSizes_ ) );
                if numel( obj.ColumnSizes_ ) > nColumns
                    obj.ColumnSizes_(nColumns+1:end,:) = [];
                end
            end
            
            % Redraw
            obj.redraw();
        end % onChildRemoved
        
    end % protected methods
    
end % classdef