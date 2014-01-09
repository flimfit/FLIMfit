classdef OMERO_data_series < flim_data_series
    
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

   
    properties
        
        
        
    end
    
    properties(Constant)
        
    end
    
    properties(SetObservable)
         
    end
    
    properties(Dependent)
        
    end
    
    properties(SetObservable,Transient)
        
    end
        
    properties(SetObservable,Dependent)
       
    end
    
    properties(Transient)
        
    end
    
    properties(Transient,Hidden)
        % Properties that won't be saved to a data_settings_file or to 
        % a project file
        
        image_ids;
        mdta;
       
        ZCT = []; % cell array containing missing OME dimensions Z,C,T (in that order)  
        verbose;        % flag to switch waitbar in OMERO_fetch on or off
        
        omero_data_manager;
        fitted_data;
        
        fit_result;
        
        FLIM_modality;
        
    end
    
    events
        
    end
    
    methods(Static)
             
    end
    
    methods
        
     function obj = OMERO_data_series(varargin)            
            handles = args2struct(varargin);
            assign_handles(obj,handles);
            obj.verbose = true;
            
            obj.polarisation_resolved = false;  % defaults
            obj.load_multiple_channels = false;
            
            obj.fitted_data = [];
            obj.fit_result = [];
            obj.FLIM_modality = [];             
        end
                                        
        function delete(obj)
            obj.fitted_data = [];
            obj.fit_result = []; 
            obj.FLIM_modality = [];            
            obj.clear_memory_mapping();
        end   
        
        %------------------------------------------------------------------
        function [param_data, mask] = get_image(obj,im,param,indexing)
            
            if ischar(param)
                param_idx = strcmp(obj.fit_result.params,param);
                param = find(param_idx);
            end
            
            param_data = squeeze(obj.fitted_data(im,:,:,param)); 
            mask = uint8(~isnan(param_data));
        end;
        
        %------------------------------------------------------------------
        function table_data = read_analysis_stats_data_from_annotation(obj,object_id)
            %
            table_data = [];
            %
            session = obj.omero_data_manager.session;
            %           
            whosobject = whos_Object(session,object_id);
            %
            if strcmp('Plate',whosobject)
                annotations = getPlateFileAnnotations(session, object_id);
            elseif strcmp('Dataset',whosobject)
                annotations = getDatasetFileAnnotations(session, object_id);               
            else
                return;
            end
            %
            rawFileStore = session.createRawFileStore();
                    %
                    for j = 1:annotations.size()
                        originalFile = annotations(j).getFile();        
                        rawFileStore.setFileId(originalFile.getId().getValue());            
                        byteArr  = rawFileStore.read(0,originalFile.getSize().getValue());
                        str = char(byteArr');
                        
                        filename_str = char(originalFile.getName().getValue());
                        %
                        if ~isempty(strfind(filename_str,'Fit Results Table'))
                            L = length(filename_str);
                            if strcmp('.csv',filename_str(L-3:L))
                                %
                                full_temp_file_name = [tempdir filename_str];
                                fid = fopen(full_temp_file_name,'w');                
                                fwrite(fid,str,'int8');                        
                                fclose(fid);                                                
                                %
                                [~,~,table_data] = xlsread(full_temp_file_name);                                                                                                                                
                                %
                                rawFileStore.close();
                                return;        
                            end
                        end                        
                    end
                    %
            rawFileStore.close();
            %                            
        end
                        
    end
    
end
