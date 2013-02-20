function write_raw_data(file,t,data,t_irf,irf,ref)

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


    if nargin < 6
        ref = [];
    end
    if nargin < 5
        irf = [];
    end
    
    n_datasets = size(data,4);
    
    [path name ext] = fileparts(file);

    dinfo = struct();
    dinfo.t = t;
    
    for i=1:n_datasets
        dinfo.names{i} = ['Data ' num2str(i)];
    end
    
    dinfo.metadata = struct();
    dinfo.metadata.FileName = dinfo.names;
    dinfo.channels = 1;
    dinfo.data_size = [size(data,1) 1 size(data,2) size(data,3) 1];
    dinfo.polarisation_resolved = false;
    dinfo.num_datasets = n_datasets;
    dinfo.mode = 'TCSPC';

    fname = [tempname '.mat'];
    save(fname,'dinfo');
    fid = fopen(fname,'r');
    byteData = fread(fid,inf,'uint8');
    fclose(fid);
    delete(fname);

    mapfile = fopen(file,'w');      

    fwrite(mapfile,length(byteData),'uint16');
    fwrite(mapfile,byteData,'uint8');
    fwrite(mapfile,data,'uint16');
    fclose(mapfile);
    
    if ~isempty(irf)
        dlmwrite([path filesep 'irf.irf'],[t_irf' irf'],'\t');
    end
    if ~isempty(ref)
        dlmwrite([path filesep 'ref150.irf'],[t_irf' ref'],'\t');
    end
end