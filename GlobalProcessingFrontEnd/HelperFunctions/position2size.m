% Extracts size information from handle graphics position vector.
%
% Input arguments:
% dims:
%    a four-element position vector storing object left and bottom
%    coordinates, as well as object width and height
%
% Example:
%    [w,h] = position2size(get(gcf, 'Position'));
%
% See also: get, set

% Copyright 2008-2009 Levente Hunyadi
function [width,height] = position2size(dims)

width = dims(3);
height = dims(4);
