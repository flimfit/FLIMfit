function ret = parse_WP_format(folder)

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

% A-7 - FOV00239

ret = [];

try
    letters = 'ABCDEFGH';
    
    dirlist = [];
    totlist = dir(folder);

        z = 0;
        for k=3:length(totlist)
            if 1==totlist(k).isdir
                z=z+1;
                dirlist{z} = totlist(k).name;
            end;
        end  
        
    dirlist = sort_nat(dirlist);
    num_dirs = numel(dirlist);
    
    rows = zeros(1,num_dirs);
    cols = zeros(1,num_dirs);
    params = zeros(1,num_dirs);
    names = cell(1,num_dirs);
    
    for i = 1 : num_dirs        
        iName = dirlist{i};        
        names{i} = iName;                
        str = split('-',iName);
        imlet = char(str(1));
        rows(1,i) = find(letters==imlet)-1;
        cols(1,i) = str2num(char(str(2)))-1;        
        %
        str = split(' _ FOV',iName);
        params(1,i) = str2num(char(str(length(str))));
    end        
        
    ret.names = names;
    ret.rows = rows;
    ret.cols = cols;
    ret.params  = params;
    ret.colMaxNum = 12;
    ret.rowMaxNum = 8;
    ret.extension = 'tif';
    ret.columnNamingConvention = 'number'; % 'Column_Names';
    ret.rowNamingConvention = 'letter'; %'Row_Names'; 
    ret.NumberOfFLIMChannels = 1;
    ret.DelayedImageFileNameParsingFunction = 'parse_DIFN_format1';
    ret.image_metadata_filename = 'Metadata.txt';% in each directory...
    
catch err
    display(err.message);    
end