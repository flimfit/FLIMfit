

file = '/Users/sean/Documents/FLIMTestData/2015-06-26 RacRho/Green Chroma Slide_3_1.pt3';

channels = [2,3];

r = FLIMreaderMex(file);
FLIMreaderMex(r, 'SetSpatialBinning', 2);
data = FLIMreaderMex(r, 'GetData', channels);
t = FLIMreaderMex(r, 'GetTimePoints')';
FLIMreaderMex(r,'Delete');

T = 12500;
omega = 2*pi/T;



d = sum(data,3);
d = sum(d,4);
plot(t,d)


%%

