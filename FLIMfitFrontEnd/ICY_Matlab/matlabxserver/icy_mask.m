
function [mask, h_roi] = icy_mask(h_fig)
%
% The function 'icy_mask' is deprecated: use 'icy_roimask' instead.
%

fprintf('The function ''icy_mask'' is deprecated: use ''icy_roimask'' instead.\n');
[mask, h_roi] = icy_roimask(h_fig);
