function new_datasetId = upload_dir_as_Dataset(session,Project,folder,extension,modulo)

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
        

%
            new_datasetId = [];
            %     

            %strings  = split(filesep,folder);
            strings1 = strrep(folder,filesep,'/');
            strings = split('/',strings1);
            %
                    files = dir([folder filesep '*.' extension]);
                    num_files = length(files);
                    if 0==num_files
                        errordlg('No suitable files in the directory');
                        return;
                    end;
                    %
                    new_dataset_name = char(strings(length(strings)));
                    description = [ 'new dataset created at ' datestr(now,'yyyy-mm-dd-T-HH-MM-SS')]; %?? duplicate
                    new_dataset = create_new_Dataset(session,Project,new_dataset_name,description);                    
                    %
                    file_names = cell(1,num_files);
                    for i=1:num_files
                        file_names{i} = files(i).name;
                    end
                    file_names = sort_nat(file_names);
                    % 
                    hw = waitbar(0, 'Loading files to Omero, please wait');
                    for i = 1 : num_files   
                        full_file_name = [folder filesep file_names{i}];
                        if ~strcmp('sdt',extension)                            
                            if strcmp('tif',extension) && is_OME_tif(full_file_name) % that ignores "modulo" specifier!..
                                upload_Image_OME_tif(session, new_dataset,full_file_name,' ');  
                            else % try to load according to "modulo"
                                U = imread(full_file_name,extension);
                                % rearrange planes
                                [w,h,Nch] = size(U);
                                Z = zeros(Nch,h,w);
                                for c = 1:Nch,
                                    Z(c,:,:) = squeeze(U(:,:,c))';
                                end;
                                img_description = ' ';               
                                pixeltype = get_num_type(U);
                                imageId = mat2omeroImage(session, Z, pixeltype, file_names{i},  img_description, [], modulo);
                                link = omero.model.DatasetImageLinkI;
                                link.setChild(omero.model.ImageI(imageId, false));
                                link.setParent(omero.model.DatasetI(new_dataset.getId().getValue(), false));
                                session.getUpdateService().saveAndReturnObject(link); 
                            end % if strcmp('tif',extension) && is_OME_tif(full_file_name)                           
                        else % strcmp('sdt',extension)
                            upload_Image_BH(session, new_dataset,full_file_name,'sample',modulo);    
                        end
                        %
                        waitbar(i/num_files, hw);
                        drawnow;
                    end
                    delete(hw);
                    drawnow;
            %
            new_datasetId = new_dataset.getId().getValue();
        end
