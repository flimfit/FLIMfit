classdef h5_serializer < handle 
    
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

    
    properties(Transient = true)
        cur_names = {};
        file;
    end
    
    methods(Abstract)
       
        post_serialize(obj);        
        post_deserialize(obj);
        
    end
    
    methods
            
        function names = get_names(obj,path)   
            names = {};
            inf = h5info(obj.file,path);
            ds = inf.Datasets;
            groups = inf.Groups;
            for i=1:length(ds)
                names{end+1} = [path ds(i).Name]; %#ok
            end
            for i=1:length(groups)
                names = [names obj.get_names([groups(i).Name '/'])]; %#ok
            end
        end
        
        function serialize(obj,file)
        
            obj.file = file;
            
            mc = metaclass(obj);
            name = mc.Name;
            
            if exist(obj.file,'file')
                try
                    names = obj.get_names(['/' name '/']);
                catch %#ok
                    names = {};
                end
            else
                names = {};
            end
            
            obj.cur_names = names;

            obj.write_struct_or_class(name,'/',obj)
            
            obj.post_serialize();
            
            h5disp(obj.file);
            
        end
        
        function deserialize(obj,file)
        
            obj.file = file;

            mc = metaclass(obj);
            name = mc.Name;
            mp = mc.Properties;
            
            fields = {};
            for i=1:length(mp)
                if mp{i}.Transient == false && mp{i}.Dependent == false && mp{i}.Constant == false
                    fields{end+1} = mp{i}.Name; %#ok
                end
            end
                
            group = ['/' name '/'];
            inf = h5info(obj.file,group);
            
            ds = inf.Datasets;
            groups = inf.Groups;
            for i=1:length(ds)
                if any(strcmp(ds(i).Name,fields))
                    obj.(ds(i).Name) = obj.read_dataset(ds(i).Name,group,ds(i).Attributes);
                end
            end
            for i=1:length(groups)
                name = groups(i).Name;
                name = name((length(group)+1):end);
                
                if any(strcmp(name,fields))
                    obj.(name) = obj.read_struct(groups(i).Name);
                end
            end
            
            obj.post_deserialize();

            
        end
        
        function data = read_struct(obj,group)
           
            group = [group '/'];
            
            inf = h5info(obj.file,group);

            data = struct();
            
            ds = inf.Datasets;
            groups = inf.Groups;
            for i=1:length(ds)
                data.(ds(i).Name) = obj.read_dataset(ds(i).Name,group,ds(i).Attributes);
            end
            for i=1:length(groups)
                name = groups(i).Name;
                name = name((length(group)+1):end);
                data.(name) = obj.read_struct(groups(i).Name);
            end
            
        end
        
        function data = read_dataset(obj,name,group,attributes)
           
            s_group = [group name];
            
            hint = '';
            for i=1:length(attributes)
               att = attributes(i);
               if strcmp(att.Name,'reader_hint')
                   hint = att.Value;
               end
            end
            
            data = h5read(obj.file,s_group);

            switch hint
                case 'cell_numeric'
                    data = num2cell(data);
            end
            
            
        end
        
        function write_struct_or_class(obj,name,group,data)
            
            if isstruct(data)
                                
                fields = fieldnames(data);
                
            elseif isobject(data)
            
                % Get information about the current object
                fields = {};
                mc = metaclass(data);
                mp = mc.Properties;
                for i=1:length(mp)
                    if mp{i}.Transient == false && mp{i}.Dependent == false && mp{i}.Constant == false
                        fields{end+1} = mp{i}.Name; %#ok
                    end
                end
            
            else
                return
            end
            
            
            
            for i=1:length(fields)
                
                s_group = [group name '/'];
                
                field = fields{i};
                fdata = data.(fields{i});

                if isempty(fdata)
                    disp(s_group);
                elseif isnumeric(fdata)                
                    obj.write_numeric(field,s_group,fdata,'numeric');
                elseif ischar(fdata)
                    fdata = uint8(fdata);
                    obj.write_numeric(field,s_group,fdata,'string');
                elseif iscell(fdata)
                    if all(cellfun(@isnumeric,fdata))
                        empty = cellfun(@isempty,fdata);
                        if sum(empty(:)) > 0
                            fdata(empty) = {NaN};
                        end
                        
                        fdata = cell2mat(fdata);
                        obj.write_numeric(field,s_group,fdata,'cell_numeric');
                    else
                        obj.write_cellstr(field,s_group,fdata);
                    end
                elseif isstruct(fdata)
                    obj.write_struct_or_class(field,s_group,fdata);
                end
                
            end
            
            h5writeatt(obj.file,s_group,'reader_hint','struct');
        end 
        
        function write_numeric(obj,name,group,data,hint)
            
            datatype = class(data);
                        
            path = [group name]
            if ~any(strcmp(obj.cur_names,path))
                h5create(obj.file,path,size(data),'Datatype',datatype);
            end
            h5write(obj.file,path,data);       
            
            if nargin == 5
                h5writeatt(obj.file,path,'reader_hint',hint);
            end
        end
        
        function write_cellstr(obj,name,group,data)
            
            empty = cellfun(@isempty,data);
            
            if sum(empty) > 0
                data{empty} = '';
            end
            
            path = [group name];
            
            % Generate a file
            fid = H5F.open(obj.file,'H5F_ACC_RDWR','H5P_DEFAULT');
            
            % Set variable length string type
            VLstr_type = H5T.copy('H5T_C_S1');
            H5T.set_size(VLstr_type,'H5T_VARIABLE');

            if ~any(strcmp(obj.cur_names,path))
                % Create a dataspace for cellstr
                H5S_UNLIMITED = H5ML.get_constant_value('H5S_UNLIMITED');
                dspace = H5S.create_simple(1,numel(data),H5S_UNLIMITED);

                % Create a dataset plist for chunking
                plist = H5P.create('H5P_DATASET_CREATE');
                H5P.set_chunk(plist,2); % 2 strings per chunk

                % Create dataset
                dset = H5D.create(fid,path,VLstr_type,dspace,plist);
                
                H5S.close(dspace);
                H5P.close(plist);
            else
                dset = H5D.open(fid,path);
            end
            
            % Write data
            H5D.write(dset,VLstr_type,'H5S_ALL','H5S_ALL','H5P_DEFAULT',data);

            % Close file & resources
            
            H5T.close(VLstr_type);
            H5D.close(dset);
            H5F.close(fid);
            
            h5writeatt(obj.file,path,'reader_hint','cell_str');

        end

        function data = read_cellstr(obj,name)

            % Open file
            fid = H5F.open(obj.file,'H5F_ACC_RDONLY','H5P_DEFAULT');

            % Set variable length string type
            VLstr_type = H5T.copy('H5T_C_S1');
            H5T.set_size(VLstr_type,'H5T_VARIABLE');

            % Open dataset
            dset = H5D.open(fid,name);

            % Read data
            str_data = H5D.read(dset,VLstr_type,'H5S_ALL','H5S_ALL','H5P_DEFAULT');

            % Close file & resources
            H5T.close(VLstr_type);
            H5D.close(dset);
            H5F.close(fid);

            % NOTE: Because variable strings are treated as 1-column cellstr, no 
            % transpose is needed.
            disp('Original cellstr:');
            disp(str);
            disp('Read cellstr from file:');
            disp(str_data);

        end
    
    end
    
end