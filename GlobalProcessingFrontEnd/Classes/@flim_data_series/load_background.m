function load_background(obj, background_file)

    %> Load a background image from a file

    try 
        im = imread(background_file);
        
        im = double(im);
        
        % correct for labview broken tiffs
        if all(im > 2^15)
            im = im - 2^15;
        end
        
        if any(size(im) ~= [obj.height obj.width])
            throw(MException('GlobalAnalysis:BackgroundIncorrectShape','Error loading background, file has different dimensions to the data'));
        else
            obj.background_image = im;
            obj.background_type = 2;
        end    
    end

    obj.compute_tr_data();
    
    %notify(obj,'data_updated');

end