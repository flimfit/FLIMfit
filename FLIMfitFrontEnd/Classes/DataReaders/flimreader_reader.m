classdef flimreader_reader < base_data_reader
   
    properties
        n_channels
        reader
    end
    
    methods
       
        function obj = flimreader_reader(filename,settings)
            obj.filename = filename;

            obj.reader = FlimReader(obj.filename);
            r = obj.reader;
            obj.n_channels = FlimReader(r,'GetNumberOfChannels');
            obj.delays = FlimReader(r,'GetTimePoints');
            obj.data_type = FlimReader(r,'GetNativeType');
            supports_realignment = FlimReader(r,'SupportsRealignment');
            
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
            
            FlimReader(r,'SetSpatialBinning',obj.settings.spatial_binning);
            FlimReader(r,'SetTemporalDownsampling',obj.settings.temporal_downsampling);
            
            if isfield(obj.settings,'realignment')
                FlimReader(r,'SetRealignmentParameters',obj.settings.realignment);
            end
            
            obj.sizeZCT = [ 1 obj.n_channels 1 ];
            obj.FLIM_type = 'TCSPC';
            obj.delays = FlimReader(r,'GetTimePoints');
            obj.sizeXY = FlimReader(r,'GetImageSize');
                        
            for i=1:obj.n_channels
                obj.chan_info{i} = ['Channel ' num2str(i-1)];
            end
            
        end
        
        function delete(obj)
            FlimReader(obj.reader,'Delete');
        end
        
        function data = read(obj, zct, channels)
               
            assert(all(zct([1,3])==1));
            
            if channels == -1
                channels = zct(2);
            end
            
            r = obj.reader;
            FlimReader(r,'SetSpatialBinning',obj.settings.spatial_binning);
            FlimReader(r,'SetTemporalDownsampling',obj.settings.temporal_downsampling);

            if isfield(obj.settings,'realignment')
                FlimReader(r,'SetRealignmentParameters',obj.settings.realignment);
            end

            
            data = FlimReader(r, 'GetData', channels - 1);
            
        end
        
        function norm = getIntensityNormalisation(obj, zct)
            norm = FlimReader(obj.reader,'GetIntensityNormalisation');
        end
        
        

        
    end
    
end