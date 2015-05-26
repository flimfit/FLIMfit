
function h_fig = icy_figure()
% h_fig = icy_figure()
%
% Allocate a new viewer in Icy, and return its handle.

args_out = icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'figure');
h_fig = double(args_out.h_fig);
