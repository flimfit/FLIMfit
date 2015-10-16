
function icy_settitle(h_fig, title)
% icy_settitle(h_fig, title)
%
% Change the title of the figure corresponding to the handle 'h_fig'

args_in.h_fig = int32(h_fig);
args_in.title = title;
icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'settitle', args_in);
