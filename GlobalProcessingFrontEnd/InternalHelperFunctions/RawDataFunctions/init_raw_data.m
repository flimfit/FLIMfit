function mapfile = init_raw_data(file,t,data_size,n_datasets,metadata,t_irf,irf,mode,pol,t_int,format)

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

    
    [path name ext] = fileparts(file);

    dinfo = struct();
    dinfo.t = t;
    
    for i=1:n_datasets
        dinfo.names{i} = ['Data ' num2str(i)];
    end
    
    if nargin < 5 || isempty(metadata)
        metadata = struct();
    end
    
    if nargin < 8
        mode = 'TCSPC';
    end
    
    if nargin < 9
        pol = false;
    end
    
    if nargin < 10 || isempty(t_int)
        t_int = ones(size(t));
    end
    
    if nargin < 11
        format = 'uint16';
    end
    
    if pol
        n_chan = 2;
    else
        n_chan = 1;
    end
    
    
    dinfo.metadata = metadata;

    if ~isfield(dinfo.metadata,'FileName');
        dinfo.metadata.FileName = dinfo.names;
    end
    
    dinfo.channels = n_chan;
    dinfo.data_size = [data_size(1) n_chan data_size(2) data_size(3)];
    dinfo.polarisation_resolved = pol;
    dinfo.num_datasets = n_datasets;
    dinfo.mode = mode;
    dinfo.t_int = t_int;
    dinfo.format = format;

    if nargin > 6
        dinfo.irf = irf;
        dinfo.t_irf = t_irf;
    end
    
    fname = [tempname '.mat'];
    save(fname,'dinfo');
    fid = fopen(fname,'r');
    byteData = fread(fid,inf,'uint8');
    fclose(fid);
    delete(fname);

    mapfile = fopen(file,'w');      

    fwrite(mapfile,length(byteData),'uint16');
    fwrite(mapfile,byteData,'uint8');
    
end