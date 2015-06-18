
function [mask, h_roi] = icy_roimask(h_fig, label)
% [mask, h_roi] = icy_roimask(h_fig)
% [mask, h_roi] = icy_roimask(h_fig, label)
%
% Ask the user to select an existing ROI or to create a new one on the figure
% identified by 'h_fig', and return the corresponding 2D boolean mask, and also
% a handle that can be used to identified the selected ROI.
%
% This function provides a similar feature than the Matlab built-in 'roipoly'
% function.

% Optional label argument
if(~exist('label', 'var'))
	label = '';
end

args_in.h_fig = int32(h_fig);
args_in.label = char(label);
args_out = icy_command('plugins.ylemontag.matlabxserver.MatlabXServerDeamon', 'roimask', args_in);
mask  = args_out.mask;
h_roi = args_out.h_roi;
