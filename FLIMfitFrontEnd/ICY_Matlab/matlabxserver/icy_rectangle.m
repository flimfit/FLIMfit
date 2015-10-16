
function h_roi = icy_rectangle(h_fig, x0, y0, width, height)
% h_roi = icy_rectangle(h_fig, x0, y0, width, height)
% h_roi = icy_rectangle(h_fig, [x0, y0, width, height])
% 
% Create a rectangular ROI in the figure identified by 'h_fig', and return a
% handle that can be used to identified this ROI.
%
% The variable 'x0' and 'y0' specify the position of the top-left corner of the
% ROI, while 'width' and 'height' determine respectively the horizontal and
% vertical dimensions of the rectangle. Be careful when setting 'x0' and 'y0',
% as Icy and Matlab does not use the same convention to identify the top-left
% coordinate of an image: (1,1) in Matlab, but (0,0) in Icy.

% Compute the coordinates
if(numel(x0)==4)
	coordinates = x0;
else
	coordinates = [x0, y0, width, height];
end
coordinates = double(coordinates);

% Execute the command
args_in.h_fig       = int32(h_fig);
args_in.coordinates = coordinates;
args_out = icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'rectangle', args_in);
h_roi = double(args_out.h_roi);
