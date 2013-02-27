function [data,t] = read_raw_data(file,index)

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


    mapfile = fopen(file,'r');
    
    ser_len = fread(mapfile,1,'uint16');
    ser_info = fread(mapfile,ser_len,'uint8');

    fname = [global_tempname '.mat'];
    fid = fopen(fname,'w');
    fwrite(fid,ser_info,'uint8');
    load(fname);
    fclose(fid);
    delete(fname);
    
    sz = dinfo.data_size';
    t = dinfo.t;
    n_datasets = dinfo.num_datasets;
        
    if nargin < 2
        index = 1:n_datasets;
    end
    
    mapfile_offset = ser_len + 2;
    mapfile_name = file;
        
    mapfile_dataoffset = prod(sz) * 2;
    
    ds = prod(sz);
    
    total_sz = sz;
    total_sz(5) = length(index);
    data = zeros(total_sz);
    
    index = index - 1;
    
    for i=1:length(index)
       
        fseek(mapfile, index(i)*mapfile_dataoffset+mapfile_offset, 'bof');
        frame = fread(mapfile,ds,'uint16');
        frame = reshape(frame,sz);
        
        data(:,:,:,:,i) = frame;
        
    end
        
    fclose(mapfile);
    
end


