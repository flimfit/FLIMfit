function SaveFPTiff(data,file)
    t = Tiff(file,'w');
    tagstruct.ImageLength = size(data,1);
    tagstruct.ImageWidth = size(data,2);
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
    tagstruct.BitsPerSample = 32;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.RowsPerStrip = 16;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    t.setTag(tagstruct);
    
    t.write(single(data));
    t.close();
end