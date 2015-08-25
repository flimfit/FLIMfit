
function icy_close(h_fig)
% icy_close(h_fig)
%
% Close all the viewers that corresponds to the handle 'h_fig'.

args_in.h_fig = int32(h_fig);
icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'close', args_in);
