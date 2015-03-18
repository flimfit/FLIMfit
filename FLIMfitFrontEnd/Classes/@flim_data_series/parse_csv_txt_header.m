function[header_data] = parse_csv_txt_header(obj, file)

% Reads the header from a single-pixel .txt  or .csv file

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


    header_data = [];
    
    if strfind(file,'.txt')
        dlm = '\t';
    else
        dlm = ',';
    end

    fid = fopen(file);

    header_data = cell(0,0);
    textl = fgetl(fid);


    if strcmp(textl,'TRFA_IC_1.0')
        fclose(fid_);
        throw(MException('FLIM:CannotOpenTRFA','Cannot open TRFA formatted files'));
        return;
    end

    while ~isempty(textl)
        first = sscanf(textl,['%f' dlm]);
        if isempty(first) || isnan(first(1))
            header_data{end+1} =  textl;
            textl = fgetl(fid);
        else
            textl = [];
        end
    end

    fclose(fid);
