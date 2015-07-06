function [data, t] = LoadImage(file)

    channels = [0,2,3];

    r = FLIMreaderMex(file);
    FLIMreaderMex(r, 'SetSpatialBinning', 4);
    data = FLIMreaderMex(r, 'GetData', channels);
    t = FLIMreaderMex(r, 'GetTimePoints')';
    FLIMreaderMex(r,'Delete');
    
    t = double(t);

end