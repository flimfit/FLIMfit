function background = GetBackground(background_file)

    [background] = LoadImage(background_file); 

    sz = size(background);

    background = reshape(background,[sz(1:2) prod(sz(3:4))]);
    background = mean(double(background),3);

end