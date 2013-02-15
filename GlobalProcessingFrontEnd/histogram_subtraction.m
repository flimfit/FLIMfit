
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



% From this paper:
% http://onlinelibrary.wiley.com/doi/10.1002/cyto.990090617/pdf

dat = csvread('C:\Users\scw09\Documents\00 Local FLIM Data\2012-09-05 Ras-Raf Anca plate\hist\histograms.csv',1,0);

x = dat(:,1);
dat = dat(:,2:end);

control = dat(:,1);
dat = dat(:,2:end);

control = control / sum(control);
dat = dat ./ sum(dat,1);

n = size(dat,1);

mpd=[];

for i=2:n
    c = sum(control(i:end));
    d = sum(dat(i:end,:),1);
    
    mpd(i-1,:) = d-c;
end

plot(mpd)
legend({'1' '2' '3' '4' '5'})
