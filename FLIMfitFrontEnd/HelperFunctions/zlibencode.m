function output_size = zlibencode(input, filename)
%ZLIBENCODE Compress input bytes with ZLIB.
%
%    output = zlibencode(input)
%
% The function takes a char, int8, or uint8 array INPUT and returns
% compressed bytes OUTPUT as a uint8 array. Note that the compression
% doesn't preserve input dimensions. JAVA must be enabled to use the
% function.
%
% See also zlibdecode typecast

%error(nargchk(1, 1, nargin));
error(javachk('jvm'));
if ischar(input), input = uint8(input); end
if ~isa(input, 'int8') && ~isa(input, 'uint8')
    error('Input must be either char, int8 or uint8.');
end

fos = java.io.FileOutputStream(filename, true); % append
zlib = java.util.zip.DeflaterOutputStream(fos);

input = input(:);

blocksize = 1024*1024;
nblock = ceil(length(input) / blocksize);

output_size = 0;
for i=1:nblock
    block_start = (i-1)*blocksize+1;
    block_end = min(block_start+blocksize-1,length(input));
    block = input(block_start:block_end);
    zlib.write(block, 0, numel(block));
end
zlib.close();
fos.close();

end