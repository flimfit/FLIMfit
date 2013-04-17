function Export_Visualisation_Images(obj,plot_controller,data_series,~)                        
                
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
    
    if ~plot_controller.fit_controller.has_fit || (~isempty(plot_controller.fit_controller.fit_result.binned) && plot_controller.fit_controller.fit_result.binned == 1)
        errordlg('..mmmm.. nothing to Export..');
        return;
    end
    
    if ~isempty(obj.dataset)
                %
                current_dataset_name = char(java.lang.String(obj.dataset.getName().getValue()));    

                if ~data_series.polarisation_resolved
                    new_dataset_name = [current_dataset_name ' FLIM MAPS ' num2str(obj.selected_channel) ...
                    ' Z ' num2str(obj.ZCT{1}) ...
                    ' C ' num2str(obj.ZCT{2}) ...
                    ' T ' num2str(obj.ZCT{3}) ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];
                else
                    new_dataset_name = [current_dataset_name ' FLIM fitting: Polarization channel ' num2str(obj.selected_channel) ...
                    ' Z ' num2str(obj.ZCT{1}) ...
                    ' C ' num2str(obj.selected_channel) ...
                    ' T ' num2str(obj.ZCT{3}) ' ' ...
                    datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                    
                end

                description  = ['analysis FLIM maps of the ' current_dataset_name ' at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')];                 
                newdataset = create_new_Dataset(obj.session,obj.project,new_dataset_name,description);                                                                                                    
                %
                if isempty(newdataset)
                    errordlg('Can not create new Dataset');
                    return;
                end
            
    f = plot_controller.fit_controller;
    r = f.fit_result;
            
        f_save = figure('visible','on');        
        save = true;
        
        root = tempdir;
      
    cnt=0;
    
    nplots = r.n_results*f.n_plots;
            
    hw = waitbar(0, 'Loading FLIM maps to Omero, please wait');
            
    ims = 1:r.n_results;
    
    for cur_im = ims

        name_root = [root ' ' r.names{cur_im}];

        if f.n_plots > 0

            for plot_idx = 1:length(f.plot_names)
            
                if f.display_normal.(f.plot_names{plot_idx})
                    
                    [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);
                    plot_controller.plot_figure(h,c,cur_im,plot_idx,true,'');                                                            
                    
                    fname = [name_root ' @ ' r.params{plot_idx}];
                     saveas(h,fname,'tif');
                     transfer_tif_to_Omero_Dataset(fname);
                    cnt=cnt+1;
                    waitbar(cnt/nplots, hw);
                    drawnow;        
                                        
                end

                % Merge
                if f.display_merged.(f.plot_names{plot_idx})
                    
                    [h,c] = tight_subplot(f_save,1,1,1,save,[r.width r.height]);                    
                    plot_controller.plot_figure(h,c,cur_im,plot_idx,true,'');                  

                    fname = [name_root ' @ ' r.params{plot_idx} ' merge'];
                     saveas(h,fname,'tif');
                     transfer_tif_to_Omero_Dataset(fname);
                    cnt=cnt+1;
                    waitbar(cnt/nplots, hw);
                    drawnow;        

                end
                
            end

        end                  
    end
    
    close(f_save)
    
    delete(hw);
    drawnow;
    
    elseif ~isempty(obj.plate) % work with SPW layout    
        %
        % TO DO..
        errordlg('SPW is not presently supported');
        %
    end
       
    function transfer_tif_to_Omero_Dataset(fname)
                            U = imread(fname,'tif');
                            %
                            pixeltype = get_num_type(U);
                            %                                             
                            %str = split(filesep,data.Directory);
                            strings1 = strrep(fname,filesep,'/');
                            str = split('/',strings1);                            
                            file_name = str(length(str));
                            %
                            % rearrange planes
                            [ww,hh,Nch] = size(U);
                            Z = zeros(Nch,hh,ww);
                            for cc = 1:Nch,
                                Z(cc,:,:) = squeeze(U(:,:,cc))';
                            end;
                            img_description = ' ';
                            imageId = mat2omeroImage(obj.session, Z, pixeltype, file_name,  img_description, [],'ModuloAlongC');
                            link = omero.model.DatasetImageLinkI;
                            link.setChild(omero.model.ImageI(imageId, false));
                            link.setParent(omero.model.DatasetI(newdataset.getId().getValue(), false)); % in this case, "project" is Dataset
                            obj.session.getUpdateService().saveAndReturnObject(link); 
    end
    
end            
