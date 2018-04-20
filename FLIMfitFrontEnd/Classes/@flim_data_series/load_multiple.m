function load_multiple(obj, polarisation_resolved, data_setting_file, channels)   
    %> Load a series of FLIM data files
    
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
    
    % get dimensions from first file
    reader = get_flim_reader(obj.file_names{1});
    obj.data_type = reader.data_type;
    %obj.rep_rate = meta.rep_rate; % TODO: rep rate
    
    if strcmp(reader.error_message,'cancelled')
        return
    elseif ~isempty(reader.error_message)
        errordlg(reader.error_message);
        return;
    end
    
    % this routine should load only FLIM data
    if length(reader.delays) < 2
        throw(MException('FLIMfit:dataNotTimeResolved','Data does not appear to be time resolved'));
    end
    
    chan_info = reader.chan_info;
    obj.mode = reader.FLIM_type;
    obj.reader_settings = reader.settings;
    obj.data_type = reader.data_type;
    
    % Determine which planes we need to load 
    [z,c,t,channels] = zct_selection_dialog(reader.sizeZCT,chan_info);
    [Z,C,T] = meshgrid(z,c,t);
    obj.ZCT = [Z(:) C(:) T(:)];
    obj.n_chan = length(channels);

    
    obj.channels = channels;
    if polarisation_resolved
        assert(length(channels) == 2);
    end
    
    images_per_file = size(obj.ZCT,1);
    n_images = length(obj.file_names);
    
    [~,names] = cellfun(@fileparts,obj.file_names,'UniformOutput',false);
    names = reshape(names,[1 length(obj.file_names)]);
    names = repmat(names,[images_per_file,1]);
    obj.names = names(:);    

    % Extract metadata 
    if isempty(obj.metadata)
        metadata.Z = num2cell(repmat(Z(:),[n_images 1]))';
        if ~all(C == -1)
            metadata.C = repmat(chan_info(C),[n_images 1])';
        end
        metadata.T = num2cell(repmat(Z(:),[n_images 1]))';   
        obj.metadata = extract_metadata(names,metadata);
    end
    
    obj.n_datasets = n_images * images_per_file;
    
    obj.t = reader.delays;
    obj.data_size = [length(reader.delays) length(channels) reader.sizeXY obj.n_datasets];
   
    delete(reader);
    
    if obj.lazy_loading
        obj.load_selected_files(1);
    else
        obj.load_selected_files(1:obj.n_datasets);
    end
   
    obj.init_dataset(data_setting_file);
       
end