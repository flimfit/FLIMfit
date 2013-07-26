
function [C,N,c] = conv2nan(X,Y,arg3)
% CONV2 2-dimensional convolution 
% X and Y can contain missing values encoded with NaN.
% NaN's are skipped, NaN do not result in a NaN output. 
% The output gives NaN only if there are insufficient input data
%
% [...] = CONV2NAN(X,Y);
% calculates 2-dim convolution between X and Y
% [C] = CONV2NAN(X,Y);

% This function is part of the NaN-toolbox
% http://www.dpmi.tu-graz.ac.at/~schloegl/matlab/NaN/
%
%	$Revision: 1.1 $
%	$Id: conv2nan.m,v 1.1 2003/12/23 10:29:26 schloegl Exp $
%	Copyright (C) 2000-2003 by Alois Schloegl <a.schloegl@ieee.org>	

% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


if nargin~=2,
        fprintf(2,'Error CONV2NAN: incorrect number of input arguments\n');
end;

m = ~isnan(X);
n = ~isnan(Y);

X(~m) = 0;
Y(~n) = 0;

C = conv2(X,Y,'same'); % 2-dim convolution
N = conv2(real(m),real(n),'same'); % normalization term
c = conv2(ones(size(X)),ones(size(Y)),'same'); % correction of normalization

if nargout==1,
        C = C.*c./N;
elseif nargout==2,
        N = N./c;
end;
