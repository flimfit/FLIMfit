function load_segmentation(obj,folder)

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
        try
            default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
        catch
            addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
            default_path = 'C:\';
        end

        folder = uigetdir(default_path,'Choose the folder containing the segmented images');
    end
        
    if folder==0
        return
    end

    folder = ensure_trailing_slash(folder);

    d = obj.data_series_controller.data_series;
    
    str = {'Replace' 'AND' 'OR' 'NAND' 'Acceptor'};
    [choice,ok] = listdlg('PromptString','How would you like to combine the selected files with the current mask?',...
                    'SelectionMode','single',...
                    'ListString',str);
    
    matching = questdlg('Use full file name or only FOV number when matching masks to images?','Image Matching','Full Match','Only FOV','Full Match');
                
                
    if ~ok
        return
    end
    
    new_sz = [d.height*d.width d.n_datasets];
    
    if isempty(obj.mask)
        new_mask = zeros(new_sz);
    else
        new_mask = reshape(obj.mask,new_sz);
    end
    
    h = waitbar(0,'Loading segmentation images');
    
    for i=1:d.n_datasets

        if strcmp(matching,'Only FOV')
            match_string = ['FOV' num2str(d.metadata.FOV{i},'%05i')];
        else
            match_string = d.names{i};
        end
        
        matching_files = [dir([folder '*' match_string '*.tif*'])
                          dir([folder '*' match_string '*.png'])];
            
        if ~isempty(matching_files)
            mask = uint16(imread([folder matching_files(1).name]));
            mask(mask>65536) = 1;
        else
            mask = ones([d.height d.width],'uint16');
        end

        if ~all(size(mask)==[d.height d.width])
            mask = imresize(mask,[d.height d.width],'nearest');
        end
        switch choice
            case 1
                new_mask(:,i) = mask(:);
            case 2
                mask = mask == 0;
                new_mask(mask(:),i) = 0;
            case 3
                mask = mask > 0;
                new_mask(mask(:),i) = 1;
            case 4
                mask = mask > 0;
                new_mask(mask(:),i) = 0;  
            case 5
                old_mask = reshape(new_mask(:,i),[d.height d.width]);
                [z,n]=bwlabel(old_mask>0,4);
                for j=1:n
                   
                    m = (z == j);
                    acc = sum(mask(m));
                    don = sum(m(:));
                    if acc/don < 0.3
                        z(m) = 0;
                    end
                    
                end
                
                z = z > 0;
                new_mask(:,i) = z(:);

                
        end
          
        waitbar(i/d.n_datasets,h);
    end
    
    close(h);
    
    obj.mask = reshape(new_mask,[d.height d.width d.n_datasets]);
    obj.filtered_mask = obj.mask;
    
    obj.update_display();

end