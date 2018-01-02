classdef (Abstract) base_data_reader < handle
    
    properties
        filename;
        
        settings;
        
        chan_info;
        delays;
        t_int;
        
    	FLIM_type;
        sizeZCT;
        sizeXY;
        data_type = 'single';
        error_message;
    end
    
    methods(Abstract)
        data = read(obj, zct, channels);
    end
    
    methods
        function im = getFlimImage(obj, zct, channels)
           
            data = obj.read(zct, channels);
            if ~any(strcmp(obj.data_type,{'single','uint16','uint32'}))
                data = single(data);
            end

            acq = struct();
            acq.data_type = strcmp(obj.FLIM_type,'TCSPC');
            acq.t_rep = 1e6/80; % TODO -> read rep rate from data
            acq.polarisation_resolved = false;
            acq.n_chan = size(data,2);
            acq.counts_per_photon = 1;    
            acq.n_x = size(data,4);
            acq.n_y = size(data,3);
            acq.t = obj.delays;
            acq.t_int = obj.t_int;

            im = ff_FLIMImage('acquisition_parmeters',acq,'data',data); 
        end
        
        function irf = getAsIrf(obj, zct, channels)
        
            data = obj.read(zct, channels);
            data = double(data);
            data = sum(sum(data,3),4);
         
            norm = sum(data,1);
            data = data ./ norm; 
            
            dt = diff(obj.delays);
            assert(all(dt == dt(1)), 'IRF data must be equally spaced');
            
            irf = struct();
            irf.irf = data;
            irf.timebin_t0 = obj.delays(1);
            irf.timebin_width = dt(1);
            
        end
        
        function norm = getIntensityNormalisation(obj, zct)
            norm = [];
        end
        
        
    end
        
    
end

