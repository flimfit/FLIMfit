function data = extract_parameter_series(folder,filter)

if nargin < 1
    folder = pwd;
end

if nargin < 2
    filter = '*';
end


files = dir([folder filter '.csv']);

file1 = [folder files(1).name];

% Get header
f = fopen(file1);
hline = fgetl(f);
hline = strrep(hline,'%','');
hline = strrep(hline,' - ','__');
hline = strrep(hline,' ','');
cols = strsplit(hline,',');
fclose(f);

data = struct();

cols = cols(2:end);

% Setup data
for i=1:length(cols)
    data.(cols{i}) = [];
end

% Read data
for i=1:length(files)
    file = [folder files(i).name]
    d = csvread(file,1,1);
    
    for j=1:length(cols)
        data.(cols{j}) = [data.(cols{j}) d(:,j)];
    end
end


