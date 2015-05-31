
function title = icy_gettitle(h_fig)
% title = icy_gettitle(h_fig)
%
% Return the title of the figure corresponding to the handle 'h_fig'.

args_in.h_fig = int32(h_fig);
args_out = icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'gettitle', args_in);
title = args_out.title;
