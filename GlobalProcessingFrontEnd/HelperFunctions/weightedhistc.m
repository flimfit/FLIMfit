%{
Copyright (c) 1995-2010 Peter Kovesi
Centre for Exploration Targeting
School of Earth and Environment
The University of Western Australia
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

Retrieved from : http://www.csse.uwa.edu.au/~pk/research/matlabfns/
%}

% WEIGHTEDHISTC   Weighted histogram count
%
% This function provides a basic equivalent to MATLAB's HISTC function for
% weighted data. 
%
% Usage: h = weightedhistc(vals, weights, edges)
%
% Arguments:
%       vals - vector of values.
%    weights - vector of weights associated with each element in vals.  vals
%              and weights must be vectors of the same length.
%      edges - vector of bin boundaries to be used in the weighted histogram.
%
% Returns:
%        h - The weighted histogram
%            h(k) will count the weighted value vals(i) 
%            if edges(k) <= vals(i) <  edges(k+1).  
%            The last bin will count any values of vals that match
%            edges(end). Values outside the values in edges are not counted. 
%
% Use bar(edges,h) to display histogram
%
% See also: HISTC

% Peter Kovesi
% Centre for Exploration Targeting
% The University of Western Australia
% peter.kovesi at uwa edu au
% 
% November 2010

function h = weightedhistc(vals, weights, edges)
    
    if ~isvector(vals) || ~isvector(weights) || length(vals)~=length(weights)
        error('vals and weights must be vectors of the same size');
    end
    
    Nedge = length(edges);
    h = zeros(size(edges));
    
    for n = 1:Nedge-1
        ind = find(vals >= edges(n) & vals < edges(n+1));
        if ~isempty(ind)
            h(n) = sum(weights(ind));
        end
    end

    ind = find(vals == edges(end));
    if ~isempty(ind)
        h(Nedge) = sum(weights(ind));
    end
    
    h = h';
    h = h/mean(weights);