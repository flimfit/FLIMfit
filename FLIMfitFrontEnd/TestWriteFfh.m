data = ones([256 1 256 256]);
data = double(data * 100);

t = 1:256;

writeFfh('test.ffh',data,t);

%%

r = FlimReaderMex('test.ffh');

t = FlimReaderMex(r,'GetTimePoints')
d = FlimReaderMex(r,'GetData',0);

FlimReaderMex(r,'Delete')

clear FlimReaderMex