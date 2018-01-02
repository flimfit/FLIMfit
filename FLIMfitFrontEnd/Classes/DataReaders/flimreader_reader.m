classdef flimreader_reader < base_data_reader
   
    properties
        n_channels
        reader
    end
    
    methods
       
        function obj = flimreader_reader(filename,settings)
            obj.filename = filename;
            obj.data_type = 'uint16';

            obj.reader = FlimReaderMex(obj.filename);
            r = obj.reader;
            obj.n_channels = FlimReaderMex(r,'GetNumberOfChannels');
            obj.delays = FlimReaderMex(r,'GetTimePoints');
            supports_realignment = FlimReaderMex(r,'SupportsRealignment');
            
            if length(obj.delays) > 1
                dt = obj.delays(2) - obj.delays(1);
            else
                dt = 1;
            end
            
            if nargin < 2 || isempty(settings)
                obj.settings = FLIMreader_options_dialog(length(obj.delays), dt, supports_realignment);
                if isempty(obj.settings)
                    obj.error_message = 'cancelled';
                end
            else
                obj.settings = settings;
            end
            
            FlimReaderMex(r,'SetSpatialBinning',obj.settings.spatial_binning);
            FlimReaderMex(r,'SetNumTemporalBits',obj.settings.num_temporal_bits);
            FlimReaderMex(r,'SetRealignmentParameters',obj.settings.realignment);
            
            obj.sizeZCT = [ 1 obj.n_channels 1 ];
            obj.FLIM_type = 'TCSPC';
            obj.delays = FlimReaderMex(r,'GetTimePoints');
            obj.sizeXY = FlimReaderMex(r,'GetImageSize');
                        
            for i=1:obj.n_channels
                obj.chan_info{i} = ['Channel ' num2str(i-1)];
            end
            
        end
        
        function delete(obj)
            FlimReaderMex(obj.reader,'Delete');
        end
        
        function data = read(obj, zct, channels)
               
            assert(all(zct([1,3])==1));
            
            if channels == -1
                channels = zct(2);
            end
            
            r = obj.reader;
            FlimReaderMex(r,'SetSpatialBinning',obj.settings.spatial_binning);
            FlimReaderMex(r,'SetNumTemporalBits',obj.settings.num_temporal_bits);
            FlimReaderMex(r,'SetRealignmentParameters',obj.settings.realignment);
            
            data = FlimReaderMex(r, 'GetData', channels - 1);
            
        end
        
        function norm = getIntensityNormalisation(obj, zct)
            norm = FlimReaderMex(obj.reader,'GetIntensityNormalisation');
        end
        
        

        
    end
    
end