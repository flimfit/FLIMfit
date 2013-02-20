function func_name = get_Plate_param_func_name_from_metadata_xml_file(filename)

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
        

    func_name = [];
    try
        tree = xml_read(filename);    
        if isfield(tree,'PlateParametersFunctionName')
            func_name = tree.PlateParametersFunctionName;
        end
    catch e
        rethrow(e);
    end

% PHOTPlateXMLmetadata.PlateParametersFunctionName = 'parse_WP_format1'; 
% xmlFileName = 'plate_reader_metadata.xml';
% xml_write(xmlFileName,PHOTPlateXMLmetadata);

