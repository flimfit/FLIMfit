function reader = get_data_reader(filename)

    % Try to initialise a bioformats reader
    try
        % Get the channel filler
        r = loci.formats.ChannelFiller();
        r = loci.formats.ChannelSeparator(r);
        
        OMEXMLService = loci.formats.services.OMEXMLServiceImpl();
        r.setMetadataStore(OMEXMLService.createOMEXMLMetadata());
        
        r.setId(filename);
                
        % filter out .tiffs for separate handling
        format = char(r.getFormat());
        %  trapdoor for formats that need to be handled outside Bio-Formats
        switch(format)
        case 'Tagged Image File Format'
            ext = '.tif'; 
        otherwise
            ext = '.bio';
        end
        
    catch exception %#ok
        % bioformats does not recognise the file
        % so work on the filename
        [~,~,ext] = fileparts_inc_OME(file);  
    end
    
    
    switch ext
        case '.bio'
            reader = bioformats_reader(filename, r);
        case {'.pt3','.ptu','.bin2','.ffd','.ffh'}
            reader = flimreader_reader(filename);
        case {'.tif','.tiff'}
            reader = tif_stack_reader(filename);
        case {'.csv','.txt'} 
            reader = text_reader(filename);
        case '.asc'
            reader = asc_reader(filename);
        case '.irf'
            reader = irf_reader(filename);
        otherwise
            throw(MException('FLIMfit:fileNotSupported','Did not recognise file'));
    end


end