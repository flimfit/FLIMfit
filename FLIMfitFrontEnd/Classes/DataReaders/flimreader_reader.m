classdef flimreader_reader < base_data_reader
   
    properties
        n_channels
    end
    
    methods
       
        function obj = flimreader_reader(filename,settings)
            obj.filename = filename;
            obj.data_type = 'uint16';

            r = FLIMreaderMex(obj.filename);
            obj.n_channels = FLIMreaderMex(r,'GetNumberOfChannels');
            obj.delays = FLIMreaderMex(r,'GetTimePoints');
            supports_realignment = FLIMreaderMex(r,'SupportsRealignment');
            
            if length(obj.delays) > 1
                dt = obj.delays(2) - obj.delays(1);
            else
                dt = 1;
            end
            
            if nargin < 2 || isempty(settings)
                obj.settings = FLIMreader_options_dialog(length(obj.delays), dt, supports_realignment);
                if isempty(obj.settings)
                    obj.error = 'cancelled';
                end
            else
                obj.settings = settings;
            end
            
            FLIMreaderMex(r,'SetSpatialBinning',obj.settings.spatial_binning);
            FLIMreaderMex(r,'SetNumTemporalBits',obj.settings.num_temporal_bits);
            FLIMreaderMex(r,'SetRealignmentParameters',obj.settings.realignment);
            
            obj.sizeZCT = [ 1 obj.n_channels 1 ];
            obj.FLIM_type = 'TCSPC';
            obj.delays = FLIMreaderMex(r,'GetTimePoints');
            obj.sizeXY = FLIMreaderMex(r,'GetImageSize');
            FLIMreaderMex(r,'Delete');
                        
            for i=1:obj.n_channels
                obj.chan_info{i} = ['Channel ' num2str(i-1)];
            end
            
        end
        
        function data = read(obj, zct, channels)
               
            assert(all(zct([1,3])==1));
            
            if channels == -1
                channels = zct(2);
            end
            
            r = FLIMreaderMex(obj.filename);
            FLIMreaderMex(r,'SetSpatialBinning',obj.settings.spatial_binning);
            FLIMreaderMex(r,'SetNumTemporalBits',obj.settings.num_temporal_bits);
            FLIMreaderMex(r,'SetRealignmentParameters',obj.settings.realignment);
            
            data = FLIMreaderMex(r, 'GetData', channels);
            
            FLIMreaderMex(r,'Delete');
            
        end
        
    end
    
end