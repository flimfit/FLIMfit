function export_intensity_images(obj, folder)
%EXPORT_INTENSITY_IMAGES Summary of this function goes here
%   Detailed explanation goes here

    h = waitbar(0,'Writing Files...');
    for i=1:obj.n_datasets  
       intensity = selected_intensity(obj,i,false);
       
       max_bits = ceil(log2(max(intensity(:)))) + 1;
       
       if max_bits > 32
           intensity = uint64(intensity);
       elseif max_bits > 16
           intensity = uint32(intensity);
       elseif max_bits > 8
           intensity = uint16(intensity);
       else
           intensity = uint8(intensity);
       end
    
       imwrite(intensity, [folder filesep obj.names{i} ' intensity.tif']);
       waitbar(i/obj.n_datasets,h)
    end
    delete(h);


end

