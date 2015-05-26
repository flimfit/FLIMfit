
function icy_clearroi(h_fig, h_roi)
% icy_clearroi(h_fig, h_roi)
%
% Clear the ROI that corresponds to the handle 'h_roi' from the figure
% identified by 'h_fig'.

args_in.h_fig = int32(h_fig);
args_in.h_roi = int32(h_roi);
icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'clearroi', args_in);
