function load_selected_files(obj,selected)

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

    if nargin < 2
        selected = 1:obj.n_datasets;
    end
        
    if ~isempty(obj.loaded)
        already_loaded = true;
        for i=1:length(selected)
            if ~obj.loaded(selected(i))
                already_loaded = false;
            end
        end

        if already_loaded
            return
        end
    end
    
    if obj.use_popup && length(selected) > 1 && ~obj.raw
        wait_handle=waitbar(0,'Opening files...');
        using_popup = true;
    else
        using_popup = false;
    end
    
    obj.clear_memory_mapping();

    obj.loaded = false(1, obj.n_datasets);
    num_sel = length(selected);

    for j=1:num_sel
        obj.loaded(selected(j)) = true;
    end
    
    if obj.hdf5
    
        %...
        
    elseif obj.raw
        
        obj.init_memory_mapping(obj.data_size(1:4), num_sel, obj.mapfile_name);
    
    else
        if obj.use_memory_mapping
            
            obj.data_type = 'single';
            
            mapfile_name = global_tempname;
            mapfile = fopen(mapfile_name,'w');

            for j=1:num_sel

                filename = '';
                try
                    if obj.load_multiple_channels
                        filename = obj.file_names{1};
                        data = obj.load_FLIM_cube(filename);
                       % [~,data] = load_flim_file(filename,obj.channels(selected(j)),obj.block);
                    else
                        filename = obj.file_names{selected(j)};
                        data = obj.load_FLIM_cube(filename);
                       % [~,data] = load_flim_file(filename,obj.channels,obj.block);
                    end
                catch
                    disp(['Warning: could not load dataset ' filename ', replacing with blank']);
                    data = zeros(obj.data_size(1:4)');
                end
                    
                
                if false && ~isdeployed
                   
                    if obj.polarisation_resolved
                        
                        data = data * 100;

                        if j==1

                            intensity = squeeze(sum(data,1));
                            para = squeeze(intensity(1,:,:));
                            perp = squeeze(intensity(2,:,:));

                            
                            [opt,metric] = imregconfig('monomodal'); 
                            [perp2,tx] = imregister2(perp,para,'rigid',opt,metric);
                            
                             figure(56)
                            subplot(1,2,1);
                            imagesc((para-perp)./(para+2*perp));
                            subplot(1,2,2);
                            imagesc((para-perp2)./(para+2*perp2));
                            
                            disp('Warning! Realigning perpendicular channel')
                        end
                        
                       
                    
                        for i=1:size(data,1)
                            
                            plane = squeeze(data(i,2,:,:));
                            plane = imtransform(plane,tx,'XData',[1 size(plane,2)],'YData',[1 size(plane,1)]);
                            data(i,2,:,:) = plane;
                        end
                        
                    end
                    
                end
                
                
                if isempty(data) || size(data,1) ~= obj.n_t || numel(data)~=prod(obj.data_size)
                    disp(['Warning: unable to load dataset ' num2str(j), '. Data size is (' num2str(size(data)), '), expected (' num2str(obj.data_size') ')'])
                    data = zeros([obj.n_t obj.n_chan obj.height obj.width]);
                end

                c1=fwrite(mapfile,data,'single');

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end

            fclose(mapfile);
            
            obj.init_memory_mapping(obj.data_size(1:4), num_sel, mapfile_name);    
        else
           
            for j=1:num_sel

                if obj.load_multiple_channels
                    filename = obj.file_names{1};
                    data = obj.load_flim_cube(filename);
                    % [~,data] = load_flim_file(filename,obj.channels(selected(j)));
                else
                    filename = obj.file_names{selected(j)};
                    data = obj.load_flim_cube(filename);
                    % [~,data] = load_flim_file(filename,obj.channels);
                end
                
                
                 if false && ~isdeployed
                   
                    if obj.polarisation_resolved && ndims(data) > 3
                        
                        data = data * 100;

                        if j==1 
                            
                            intensity = squeeze(sum(data,1));
                            para = squeeze(intensity(1,:,:));
                            perp = squeeze(intensity(2,:,:));

                            
                            mask = (perp+para) < 20000;
                            
                            
                            [opt,metric] = imregconfig('multimodal'); 
                            [perp2,tx] = imregister2(perp,para,'rigid',opt,metric);
                            
                            a1 = (para-perp)./(para+2*perp);
                            a2 = (para-perp2)./(para+2*perp2);
                            
                            a1(mask) = 0;
                            a2(mask) = 0;
                            
                            
                            figure(56)
                            subplot(1,2,1);
                            imagesc(a1);
                            caxis([0.2 0.5])
                            subplot(1,2,2);
                            imagesc(a2);
                            caxis([0.2 0.5]);
                            disp('Warning! Realigning perpendicular channel')
                        end
                        
                       
                    
                        for i=1:size(data,1)
                            
                            plane = squeeze(data(i,2,:,:));
                            plane = imtransform(plane,tx,'XData',[1 size(plane,2)],'YData',[1 size(plane,1)]);
                            data(i,2,:,:) = plane;
                        end
                        
                    end
                    
                end
                
                
                
                
                obj.data_series_mem(:,:,:,:,j) = single(data);
                

                if using_popup
                    waitbar(j/num_sel,wait_handle)
                end

            end
            
            obj.active = 1;
            obj.cur_data = obj.data_series_mem(:,:,:,:,1);
            
        end

    end
        
            
    if using_popup
        close(wait_handle)
    end
    
    obj.compute_tr_data(false);
    
    
end