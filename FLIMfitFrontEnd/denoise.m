function settings = denoise(filename,settings)
    
    if nargin < 2
        settings = [];
    end

    [path,file] = fileparts(filename);

    reader = get_flim_reader(filename,settings);
    settings = reader.settings;

    data = reader.read([1 1 1],1:reader.n_channels);
    t = reader.delays;

    denoised = zeros(size(data),'single');
    denoised = single(data);

    
    for i=1:size(data,1)
        for j=1:size(data,2)
            disp(num2str([i, j]));
            slice = squeeze(double(data(i,j,:,:)));
            if sum(slice) > 0
                slice = iterVSTpoisson(slice);
            end
            denoised(i,j,:,:) = single(slice);
        end
    end

    
    writeFfh([path filesep file '_denoised.ffh'],denoised,t);



