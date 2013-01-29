% stream raw data example

file = 'test2.raw';

t = 1:10;
n_datasets = 100;
data_size = [length(t) 256 256];

% open the file
f = init_raw_data(file,t,data_size,n_datasets);

for i=1:n_datasets
    % generate some random data
    data = rand(data_size) * 2^8;
    data = uint16(data);

    %write it
    fwrite(f,data,'uint16');
end

fclose(f);