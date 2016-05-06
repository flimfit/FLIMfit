function load_single_segmentation(obj,file)

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


    str = {'Replace' 'AND' 'OR' 'NAND'};
    [choice,ok] = listdlg('PromptString','How would you like to combine the selected files with the current mask?',...
                    'SelectionMode','single',...
                    'ListString',str);

    if ~ok
        return
    end
    
    d = obj.data_series_controller.data_series;
    
    mask = uint16(imread(file));
    mask = repmat(mask,[1 1 d.n_datasets]);

    switch choice
        case 1
            obj.mask = mask;
        case 2
            mask = mask == 0;
            obj.mask(mask) = 0;
        case 3
            mask = mask > 0;
            obj.mask(mask) = 1;
        case 4
            mask = mask > 0;
            obj.mask(mask) = 0;        
    end
    
    obj.filtered_mask = obj.mask;
    
    obj.update_display();
end