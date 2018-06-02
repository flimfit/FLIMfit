data = ones([256 1 256 256]);
data = double(data * 100);

t = 1:256;

writeFfh('test.ffh',data,t);

%%

r = FlimReader('test.ffh');

t = FlimReader(r,'GetTimePoints')
d = FlimReader(r,'GetData',0);

FlimReader(r,'Delete')

clear FlimReaderMex