function export_intensity_images(obj, folder)
%EXPORT_INTENSITY_IMAGES Summary of this function goes here
%   Detailed explanation goes here

    h = uiwait(0,'Writing Files...');
    for i=1:obj.n_datasets  
       intensity = selected_intensity(obj,i,false);
       intensity = uint16(intensity);
       imwrite(intensity, [folder filesep obj.names{i} '-intensity.tif']);
       uiwait(i/obj.n_datasets,h)
    end
    delete(h);


end

