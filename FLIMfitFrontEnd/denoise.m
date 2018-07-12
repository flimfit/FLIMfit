function settings = denoise(filename,settings)
    
    if nargin < 2
        settings = [];
    end

    [path,file] = fileparts(filename);

    reader = get_flim_reader(filename,settings);
    settings = reader.settings;

    data = reader.read([1 1 1],1:reader.n_channels);
    t = reader.delays;

%    denoised = zeros(size(data),'single');
%    denoised = single(data);
    
    mode = 'FastHyDe';
    
    if strcmp(mode,'FastHyDe')

        sz = size(data);
        data = permute(data, [3 4 1 2]);
        data = reshape(data, [sz(3:4) sz(1)*sz(2)]);

        s = sum(sum(data,2),1) > 0;
        s = s(:);

        sel_data = data(:,:,s);

        sel_denoised = FastHyDe(double(sel_data), 'additive', 0, 5);

        denoised = zeros(size(data));
        denoised(:,:,s) = sel_denoised;
        denoised = single(denoised);

        denoised = reshape(denoised,[sz(3:4) sz(1:2)]);
        denoised = permute(denoised,[3 4 1 2]);
    else
        
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
    end
    
    writeFfh([path filesep file '_denoised.ffh'],denoised,t);



