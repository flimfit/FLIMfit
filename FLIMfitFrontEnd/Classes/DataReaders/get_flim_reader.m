function reader = get_flim_reader(filename,settings)

    if nargin < 2
        settings = [];
    end

    [~,~,ext] = fileparts_inc_OME(filename);

    switch ext
        case {'.pt3','.ptu','.bin2','.ffd','.ffh','.sdt','.ics'}
            reader = flimreader_reader(filename,settings);
        case {'.tif','.tiff'}
            reader = tif_stack_reader(filename);
        case {'.csv','.txt'} 
            reader = text_reader(filename);
        case '.asc'
            reader = asc_reader(filename);
        case '.irf'
            reader = irf_reader(filename);
        otherwise
            reader = bioformats_reader(filename);
    end
    
end