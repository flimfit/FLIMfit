function sim_write_bh(filename,simimage,x_size,y_size,timegates)

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