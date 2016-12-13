classdef flim_file_info
   
    properties
       
        filename;
        
        chan_info;
        delays;
    	FLIM_type = [];
        sizeZCT = [];
        error_message = [];

        modulo = [];
        image_series = [];
        
        bf_reader;
        ext;
    end
    
    methods
        
        function obj = flim_data_info(filename)
            obj.filename = filename;
            obj.try_bfreader();
            
            switch obj.ext
                case '.bio'
                    obj.process_bioformats();
                case {'.pt3','.ptu','.bin2','.ffd','.ffh'}
                    obj.process_flimreader();
                case {'.tif','.tiff'}
                    obj.process_tif_stack();
                case {'.csv','.txt'} 
                    obj.process_text();
                case '.asc'
                    obj.process_asc();
                case '.irf'
                    obj.process_irf();
                otherwise
                    throw(MException('FLIMfit:fileNotSupported','Did not recognise file'));
            end
        end
        
        function process_bioformats(obj)
            
        end
        
    end
    
    
end