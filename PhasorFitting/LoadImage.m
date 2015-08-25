function [data, t] = LoadImage(file)

    buffer_file = [file '-phasor.mat'];

    if ~exist(buffer_file,'file')

        channels = [0,2,3];

        r = FLIMreaderMex(file);
        FLIMreaderMex(r, 'SetSpatialBinning', 2);
        data = FLIMreaderMex(r, 'GetData', channels);
        t = FLIMreaderMex(r, 'GetTimePoints')';
        FLIMreaderMex(r,'Delete');

        t = double(t);
        
        save(buffer_file,'data','t');
    
    else
    
        r = load(buffer_file);
        data = r.data;
        t = r.t;
        
    end
end