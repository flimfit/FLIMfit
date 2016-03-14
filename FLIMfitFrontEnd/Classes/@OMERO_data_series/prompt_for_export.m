function [filename, pathname, selected, before_list] = prompt_for_export(obj,prompt,default_name, extString)
    %> Prompt the user for root file name & image type (TBD Dataset)
    
    % Copyright (C) 2015 Imperial College London.
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
   
    client = obj.omero_logon_manager.client;
    userid = obj.omero_logon_manager.userid;
    
    
    
    if obj.datasetForOutputId < 1
        dataID = javaObject('java.lang.Long',obj.datasetId);
    else
        dataID = javaObject('java.lang.Long',obj.datasetForOutputId);
    end
     
    type = 1;       % by default select a dataset
    
    if strcmp(extString,'.tiff') 
        fnameStrings = javaArray('java.lang.String',6);
        fnameStrings(1) = java.lang.String(default_name);
        fnameStrings(2) = java.lang.String(prompt);
        fnameStrings(3) = java.lang.String('.tiff');
        fnameStrings(4) = java.lang.String('.pdf');
        fnameStrings(5) = java.lang.String('.png');
        fnameStrings(6) = java.lang.String('.eps');
    else
        fnameStrings = javaArray('java.lang.String',3);
        fnameStrings(1) = java.lang.String(default_name);
        fnameStrings(2) = java.lang.String(prompt);
        fnameStrings(3) = java.lang.String(extString);
        
        % if saving a text file check if we are working from a plate
        if obj.datasetId < 0 && obj.plateId > 0;
            type = 2;   % type 2 = plate
            dataID = javaObject('java.lang.Long',obj.plateId);
        end
    end
     
    if type == 2
        chooser = OMEuiUtils.OMEROImageChooser(client, userid, type, false, dataID, fnameStrings );
        selected = chooser.getSelectedPlate();
    else
        chooser = OMEuiUtils.OMEROImageChooser(client, userid, dataID, fnameStrings );
        selected = chooser.getSelectedDataset();
    end
   
    if ~isempty(selected)
        filename = char(chooser.getFilename());
        id = selected.getId.getValue();
        if id ~= obj.datasetId && type == 1
            obj.datasetForOutputId = id;
        end
        
        clear chooser;
        pathname = tempdir;
        c = strsplit(filename,'.');
        search_string = [pathname c{1} '*.*'];
        before_list = dir(search_string);
    else
        filename=0;
        pathname = 0;
        before_list = [];
    end
   
end