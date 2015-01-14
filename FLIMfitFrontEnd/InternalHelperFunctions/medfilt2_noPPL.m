function b = medfilt2_noPPL(varargin)
%MEDFILT2 2-D median filtering omits test of UseIPPL preference
% Otherwise duplicates standard medfilt2

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).




[a, mn, padopt] = parse_inputs(varargin{:});


domain = ones(mn);
if (rem(prod(mn), 2) == 1)
    order = (prod(mn)+1)/2;
    b = ordfilt2(a, order, domain, padopt);
else
    order1 = prod(mn)/2;
    order2 = order1+1;
    b = ordfilt2(a, order1, domain, padopt);
    b2 = ordfilt2(a, order2, domain, padopt);
	if islogical(b)
		b = b | b2;
	else
		b =	imlincomb(0.5, b, 0.5, b2);
	end
end


%%%
%%% Function parse_inputs
%%%
function [a, mn, padopt] = parse_inputs(varargin)
narginchk(1,4);

% Any syntax in which 'indexed' is followed by other arguments is discouraged.
%
% We have to catch and parse this successfully, so we're going to use a strategy
% that's a little different that usual.
%
% First, scan the input argument list for strings.  The
% string 'indexed', 'zeros', or 'symmetric' can appear basically
% anywhere after the first argument.
%
% Second, delete the strings from the argument list.
%
% The remaining argument list can be one of the following:
% MEDFILT2(A)
% MEDFILT2(A,[M N])
% MEDFILT2(A,[M N],[Mb Nb]) - errors as of R2011b
%
% -sle, March 1998

a = varargin{1};
% validate that the input is a 2D, real, numeric or logical matrix.
validateattributes(a, {'numeric','logical'}, {'2d','real'}, mfilename, 'A', 1);

charLocation = [];
for k = 2:nargin
    if (ischar(varargin{k}))
        charLocation = [charLocation k]; %#ok<AGROW>
    end
end

if (length(charLocation) > 1)
    % More than one string in input list
    error(message('images:medfilt2:tooManyStringInputs'));
elseif isempty(charLocation)
    % No string specified
    padopt = 'zeros';
else
    options = {'indexed', 'zeros', 'symmetric'};

    padopt = validatestring(varargin{charLocation}, options, mfilename, ...
                          'PADOPT', charLocation);
    
    varargin(charLocation) = [];
end

if (strcmp(padopt, 'indexed'))
    if (isa(a,'double'))
        padopt = 'ones';
    else
        padopt = 'zeros';
    end
end

if length(varargin) == 1,
  mn = [3 3];% default
elseif length(varargin) >= 2  
    mn = varargin{2}(:)';
    validateattributes(mn,{'numeric'},{'row','nonempty','real','nonzero','integer','nonnegative'},...
        mfilename,'[M N]',2);
    validateattributes(mn(1),{'numeric'},{'nonzero'},mfilename,'[M N]',2);
    validateattributes(mn(2),{'numeric'},{'nonzero'},mfilename,'[M N]',2);
    if (size(mn,2)~=2)
        error(message('images:medfilt2:secondArgMustConsistOfTwoUnsignedInts'))
    end
    
    if length(varargin) > 2
        % Error if [Mb Nb] argument is present
        error(message('images:removed:syntaxNoReplacement','MEDFILT2(A,[M N],[Mb Nb],...)'))
    end
end


% -------------------------------------------------------------------------
function A = hPadImage(A, domain, padopt)
% pad the image suitably - 
domainSize = size(domain);
center = floor((domainSize + 1) / 2);
[r,c] = find(domain);
r = r - center(1);
c = c - center(2);
padSize = [max(abs(r)) max(abs(c))];
if (strcmp(padopt, 'zeros'))
    A = padarray(A, padSize, 0, 'both');
elseif (strcmp(padopt, 'symmetric'))
    A = padarray(A, padSize, 'symmetric', 'both');
else
%   This block should never be reached.
    error(message('images:medfilt2:incorrectPaddingOption'))
end
