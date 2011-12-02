
folder = 'C:\Users\scw09\Documents\Local FLIM Data\2010-12-20 Cliff Nano Simulation\EvenAmps 50000 photons Old\';

flimage = zeros(256,64,64);

for col=1:64
    for row=1:64
        
        data = dlmread([folder 'col ' num2str(col) ' pix ' num2str(row) '.txt']);
        times = data(:,1);
        decay = data(:,2);
                
        flimage(:,row,col) = decay;
   
    end
end

%%

flimage = uint16(flimage);

folder = 'C:\Users\scw09\Documents\Local FLIM Data\2010-12-20 Cliff Nano Simulation\TifData\';

for i=1:256
   
    imwrite(squeeze(flimage(i,:,:)),[folder 'del' sprintf('%05.0f',times(i)*1000) '.tif']);
    
end