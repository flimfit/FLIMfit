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
    
    extent = extent*2+1;
        
    kernel1 = ones([extent 1]) / extent;
    kernel2 = ones([1 extent]) / extent;
    
            
    for i = 1:n_t
        for j = 1:n_chan
            plane = squeeze(data(i,j,:,:));
           
            
            if strcmp(mode,'wiener')
                %noise = 1./plane;
                %noise(isnan(noise)) = 1e10;
                plane(isnan(plane)) = 0;
                filtered = wiener2(plane,[extent,extent],noise);
            else
                %noise = sqrt(plane);
                %filtered = wiener2(plane,[extent,extent],noise);
                %med = medfilt2(plane,[extent extent]);
               
                filtered = conv2nan(plane,kernel1);                
                filtered = conv2nan(filtered,kernel2);                
            end
            %figure(7);
            %subplot(1,3,1); imagesc(plane); caxis([0 60]); daspect([1 1 1])
            %subplot(1,3,2); imagesc(filtered); caxis([0 60]); daspect([1 1 1])
            %subplot(1,3,3); imagesc(med); caxis([0 60]); daspect([1 1 1])
            
            data(i,j,:,:) = filtered;
        end
    end
end