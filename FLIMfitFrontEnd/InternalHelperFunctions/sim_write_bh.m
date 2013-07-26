function sim_write_bh(filename,simimage,x_size,y_size,timegates)

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


if x_size==256
    dummy_file='sample256.sdt';
else 
    dummy_file='sample1.sdt';
end

copyfile(dummy_file,filename);

fid=fopen(filename,'r+');

fread(fid,1,'uint16');
%Software Revision

fread(fid,1,'uint32');
%General Info Pos

fread(fid,1,'uint16');
%Length of General Info

fread(fid,1,'uint32');
%System setup offset

fread(fid,1,'uint16');
%Setup length

data_hd_offset = fread(fid,1,'uint32');
%Data header offset

fseek(fid,data_hd_offset,'bof');
dummy=fread(fid,1,'uint16');
datapos=fread(fid,1,'uint32')

blocklength = timegates*x_size*y_size;

fseek(fid,datapos,'bof');
 
fwrite(fid,simimage,'uint16');



fclose(fid);