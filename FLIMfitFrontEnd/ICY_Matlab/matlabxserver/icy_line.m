
function h_roi = icy_line(h_fig, x1, y1, x2, y2)
% h_roi = icy_line(h_fig, x1, y1, x2, y2)
% h_roi = icy_line(h_fig, [x1, y1, x2, y2])
% 
% Create a linear ROI in the figure identified by 'h_fig', and return a
% handle that can be used to identified this ROI.
%
% The line will be created between the points (x1,y1) and (x2,y2), where 'x1'
% and 'x2' represent horizontal coordinates, and 'y1' and 'y2' vertical
% coordinates. Be careful when setting these values, as Icy and Matlab does not
% use the same convention to identify the top-left coordinate of an image:
% (1,1) in Matlab, but (0,0) in Icy.

% Compute the coordinates
if(numel(x1)==4)
	coordinates = x1;
else
	coordinates = [x1, y1, x2, y2];
end
coordinates = double(coordinates);

% Execute the command
args_in.h_fig       = int32(h_fig);
args_in.coordinates = coordinates;
args_out = icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'line', args_in);
h_roi = double(args_out.h_roi);
