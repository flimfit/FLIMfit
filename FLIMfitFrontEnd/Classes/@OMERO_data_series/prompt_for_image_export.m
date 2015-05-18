function [filename, pathname, before_list] = prompt_for_image_export(obj,default_path,default_name)
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

    prompt={'Enter Root filename:',...
        'Enter image type from: tiff,pdf,png,eps'};
    name='Select root name & type';
    numlines=1;
    default_answer={default_name,'tiff'};
    answer=inputdlg(prompt,name,numlines,default_answer);
    
    if ~isempty(answer)
        pathname = tempdir;
        filename = [ answer{1} '.' answer{2} ];
        search_string = [pathname filesep answer{1} '*.*'];
        before_list = dir(search_string);
    else
        filename=0;
        pathname = 0;
        before_list = [];
    end
   
end