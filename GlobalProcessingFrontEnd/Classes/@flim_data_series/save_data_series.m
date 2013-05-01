function save_data_series(obj,file)
    %> Save data series to HDF file
    
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

    hdf_root = 'GlobalFLIMDataSeries/';
    
    % Check if file exists, if so append it to the data
    if ~exist(file,'file')
        
        % Create file
        fcpl = H5P.create('H5P_FILE_CREATE');
        fapl = H5P.create('H5P_FILE_ACCESS');
        fid = H5F.create(file,'H5F_ACC_TRUNC',fcpl,fapl);
        H5F.close(fid); 
        
        hdf5write(file,[hdf_root 't'],obj.t,'WriteMode','append');
        hdf5write(file,[hdf_root 'width'],obj.width,'WriteMode','append');
        hdf5write(file,[hdf_root 'height'],obj.height,'WriteMode','append');
        hdf5write(file,[hdf_root 'mode'],obj.mode,'WriteMode','append');

    else
            
        width = hdf5read(file,[hdf_root 'width']);
        height = hdf5read(file,[hdf_root 'height']);
        t = hdf5read(file,[hdf_root 't']);
            
        % Check if we can append data
        if width ~= obj.width || height ~= obj.height || ~all(t == obj.t)
            msgbox('Could not append data to that datafile');
            return;
        end
        
    end

    % Add data to file
    for i=1:obj.n_datasets
        dataset = [hdf_root 'FLIMData/' obj.names{i} ];
        obj.switch_active_dataset(i);
        hdf5write(file,dataset,obj.cur_data,'WriteMode','append');
    end


end