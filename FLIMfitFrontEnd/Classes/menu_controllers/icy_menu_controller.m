classdef icy_menu_controller < handle
    
    
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
        fit_controller;
        data_series_controller;
    end
    
    methods(Access=private)
          
        function export_volume(obj,mode,~)            
                        
            n_planes = obj.data_series_controller.data_series.n_datasets;
            
            params = obj.fit_controller.fit_result.fit_param_list();                        
            
            param_array(:,:) = obj.fit_controller.get_image(1, params{1});                                    
            sizeY = size(param_array,1);
            sizeX = size(param_array,2);                                        

            params_extended = [params 'I_mean_tau_chi2'];
            
            [param,v] = listdlg('PromptString','Choose fitted parameter',...
                'SelectionMode','single',...
                'ListSize',[150 200],...                                        
                'ListString',params_extended);                                    
            if (~v), return, end;
            
            full_filename = obj.data_series_controller.data_series.file_names{1};
            file_name = 'xxx ';
            if ischar(full_filename)
                C = strsplit(full_filename,filesep);
                file_name = char(C(length(C)));
            else % omero                
                image = obj.data_series_controller.data_series.file_names{1};
                file_name = char(image.getName.getValue);               
            end
            
            file_name = ['FLIMfit result ' params_extended{param} ' ' file_name];
            
            % usual way
            if param <= length(params)
                volm = zeros(sizeX,sizeY,n_planes,'single');
                for p = 1 : n_planes                
                    plane = obj.fit_controller.get_image(p,params{param})';
                    volm(:,:,p) = cast(plane,'single');
                end
                
                volm(isnan(volm))=0;
                volm(volm<0)=0;
                    
                if strcmp(mode,'send to Icy')
                    try
                        icy_im3show(volm,file_name);                    
                    catch
                        errordlg('error - Icy might be not running');
                    end
                elseif strcmp(mode,'save as OME.tiff')
                    [filename, pathname] = uiputfile('*.OME.tiff','Save as',default_path);
                    if filename ~= 0
                        bfsave(reshape(volm,[sizeX,sizeY,1,n_planes,1]),[pathname filename],'dimensionOrder','XYCZT','Compression', 'LZW','BigTiff', true);
                    end                                                            
                end
                
            elseif strcmp(params_extended{param},'I_mean_tau_chi2') % check not needed, actually 
                
                % find indices
                ind_intensity = [];
                ind_lifetime = [];
                ind_chi2 = [];                       
                for k=1:length(params), if strcmp(char(params{k}),'I'), ind_intensity=k; break; end; end; 
                for k=1:length(params), if strcmp(char(params{k}),'mean_tau'), ind_lifetime=k; break; end; end; 
                for k=1:length(params), if strcmp(char(params{k}),'chi2'), ind_chi2=k; break; end; end;                   
                if isempty(ind_lifetime) % case of single-exponential fit
                    for k=1:length(params), if strcmp(char(params{k}),'tau_1'), ind_lifetime=k; break; end; end; 
                end
                
                if ~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)
                    
                    volm = zeros([sizeX,sizeY,3,n_planes,1],'single'); % XYCZT                    
                    for p = 1 : n_planes                
                        plane_intensity = obj.fit_controller.get_image(p,params{ind_intensity})';
                        plane_lifetime = obj.fit_controller.get_image(p,params{ind_lifetime})';
                        plane_chi2 = obj.fit_controller.get_image(p,params{ind_chi2})';
                        volm(:,:,1,p,1) = cast(plane_intensity,'single');
                        volm(:,:,2,p,1) = cast(plane_lifetime,'single');
                        volm(:,:,3,p,1) = cast(plane_chi2,'single');                        
                    end                    
                    
                    volm(isnan(volm))=0;
                    volm(volm<0)=0;                    
                        
                    if strcmp(mode,'send to Icy')
                        try
                            icy_imshow(volm,file_name);                                                
                        catch
                            errordlg('error - Icy might be not running');
                        end   
                    elseif strcmp(mode,'save as OME.tiff')
                        [filename, pathname] = uiputfile('*.OME.tiff','Save as',default_path);
                        if filename ~= 0
                            bfsave(volm,[pathname filename],'dimensionOrder','XYCZT','Compression', 'LZW','BigTiff', true);
                        end                                                                                   
                    end                    
                    
                end %~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)
                
           end
                                                            
        end % export_volume
    end
    
    methods
        
        function obj = icy_menu_controller(handles)
            assign_handles(obj,handles);
            assign_callbacks(obj,handles);
        end
        
        
        function menu_file_export_volume_to_icy(obj)
            try
                obj.export_volume('send to Icy');            
            catch
                errordlg('error - there might be no fitted data');
            end
        end

        function menu_file_export_volume_as_OMEtiff(obj)
            try
                obj.export_volume('save as OME.tiff');            
            catch
                errordlg('error - there might be no fitted data');
            end
            
        end

        function menu_file_export_volume_batch(obj)            

            % try batch here            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            folder = uigetdir(default_path,'Select the folder containing the datasets');
            if folder == 0, return, end;
                
                path_parts = split(filesep,folder);
                batch_folder = [folder filesep '..' filesep 'Batch fit - ' path_parts{end} ' - ' datestr(now,'yyyy-mm-dd HH-MM-SS')];
                mkdir(batch_folder);
                
                files = dir([folder filesep '*.OME.tiff']);
                num_datasets = size(files,1);                                
                                
                for k=1:num_datasets
                    
                    obj.data_series_controller.data_series = flim_data_series();
                    obj.data_series_controller.data_series.all_Z_volume_loading = true;
                    obj.data_series_controller.data_series.batch_mode = true; 
                    
                    obj.data_series_controller.load_single([ folder filesep char(files(k).name)]);
                    obj.data_series_controller.data_series.binning = 0;
                    notify(obj.data_series_controller.data_series,'masking_updated');                    
                                        
                    obj.fit_controller.fit();                    
                    if obj.fit_controller.has_fit == 0
                        uiwait();
                    end                    
                    %
                    % [data, row_headers] = obj.fit_controller.get_table_data();
                    str = char(files(k).name);                    
                    str = str(1:length(str)-8);                      
                    param_table_name = [str 'csv'];
                    obj.fit_controller.save_param_table([batch_folder filesep param_table_name]);
                    
                    %%%%%%%%%%%%%%%%%% save parameters as OME.tiff
                    n_planes = obj.data_series_controller.data_series.n_datasets;                    
                    params = obj.fit_controller.fit_result.fit_param_list();                                            
                    param_array(:,:) = obj.fit_controller.get_image(1, params{1});                                    
                    sizeY = size(param_array,1);
                    sizeX = size(param_array,2);                                        
                    
                    % find indices
                    ind_intensity = [];
                    ind_lifetime = [];
                    ind_chi2 = [];                       
                    for m=1:length(params), if strcmp(char(params{m}),'I'), ind_intensity=m; break; end; end; 
                    for m=1:length(params), if strcmp(char(params{m}),'mean_tau'), ind_lifetime=m; break; end; end; 
                    for m=1:length(params), if strcmp(char(params{m}),'chi2'), ind_chi2=m; break; end; end;   
                    if isempty(ind_lifetime) % case of single-exponential fit
                        for m=1:length(params), if strcmp(char(params{m}),'tau_1'), ind_lifetime=m; break; end; end; 
                    end
                    
                    if ~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)

                        volm = zeros([sizeX,sizeY,3,n_planes,1],'single'); % XYCZT                    
                        for p = 1 : n_planes                
                            plane_intensity = obj.fit_controller.get_image(p,params{ind_intensity})';
                            plane_lifetime = obj.fit_controller.get_image(p,params{ind_lifetime})';
                            plane_chi2 = obj.fit_controller.get_image(p,params{ind_chi2})';
                            volm(:,:,1,p,1) = cast(plane_intensity,'single');
                            volm(:,:,2,p,1) = cast(plane_lifetime,'single');
                            volm(:,:,3,p,1) = cast(plane_chi2,'single');                        
                        end                    

                        volm(isnan(volm))=0;
                        volm(volm<0)=0;                    

                        ometifffilename = [batch_folder filesep str(1:length(str)-1) ' fitting results.OME.tiff'];
                        bfsave(volm,ometifffilename,'dimensionOrder','XYCZT','Compression', 'LZW','BigTiff', true);

                    end %~isempty(ind_intensity) && ~isempty(ind_lifetime) && ~isempty(ind_chi2)                                       
                    %%%%%%%%%%%%%%%%%% save parameters as OME.tiff
                end
        end
        
    end
    
end
