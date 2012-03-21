function data = smooth_flim_data(data,extent,mode)

    if nargin < 3
        mode = 'rectangular';
    end
    
    s = size(data);
    n_t = s(1);
    n_chan = s(2);
    
    if length(s) == 2
        return
    end
    
    extent = extent + 1;
        
    if strcmp(mode,'gaussian')
        kernel = fspecial('gaussian', [extent, extent]*2, extent);
    elseif strcmp(mode,'rectangular')
        kernel = ones([extent extent]);
    end
    
    % Normalise kernel
    %kernel = kernel / sum(kernel(:));
        
    for i = 1:n_t
        for j = 1:n_chan
            plane = squeeze(data(i,j,:,:));
           
            
            if strcmp(mode,'wiener')
                %noise = 1./plane;
                %noise(isnan(noise)) = 1e10;
                plane(isnan(plane)) = 0;
                filtered = wiener2(plane,[extent,extent],noise);
            else
                filtered = conv2nan(plane,kernel);                
            end
            filtered(isnan(filtered)) = 0;
            data(i,j,:,:) = filtered;
        end
    end
end