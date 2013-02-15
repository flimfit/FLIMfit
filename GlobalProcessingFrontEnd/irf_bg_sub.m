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

% Author : Sean Warren



irf_file = 'Y:\User Lab Data\Doug Kelly\2012\08 August\2012-08-02 Calibration Dyes Old HRI\Eryth 20uM\2012-08-02 17-59-55 INT_001000 T_02500.tif';
bg_file = 'Y:\User Lab Data\Doug Kelly\2012\08 August\2012-08-02 Calibration Dyes Old HRI\MilliQ\2012-08-02 19-35-11 INT_001000 T_02500.tif';

[t,irf]  = load_flim_file(irf_file);
[t,data] = load_flim_file(bg_file);

%%

sz = size(irf);

irf = reshape(irf,[sz(1) prod(sz(2:end))]);
data = reshape(data,[sz(1) prod(sz(2:end))]);

%%

bg_sub = irf - data;

%%

write_flim_tifs('Y:\User Lab Data\Doug Kelly\2012\08 August\2012-08-02 Calibration Dyes Old HRI\Background Subtracted IRF\',t,bg_sub)

%%
figure

a = mean(irf,2)-200;
b = mean(bg_sub,2);
c = mean(irf,2)-mean(data,2);

semilogy([a/max(a) b/max(b) c/max(c)])