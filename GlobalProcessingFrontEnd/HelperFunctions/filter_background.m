folder = 'Y:\User Lab Data\Sean Warren\00 MicroscopyData\Imperial\Multiplexed\2011-10-26 AKT-PH\bg 5s\';

fdrs = dir(folder);

img = {};

for i=2:length(fdrs)
    
   if isdir([folder fdrs(i).name])
        f = [folder fdrs(i).name];
        images = dir([f '\*.tif']);
        for j=1:length(images)
           
            img{end+1} = imread([f filesep images(j).name]);
            
            img{end} = double(img{end} - 32768);
            
        end
   end
    
    
end

mn = 0;

for i=1:length(img)
    
    mn = mn + img{i};
    
end

mn = mn / length(img);
%%
%kernel = ones(3,3);
%kernel = kernel / sum(kernel(:));

mns = medfilt2(mn,[3 3]);   

imagesc(mns)

SaveFPTiff(mns,[folder '\mean_bg.tif']);
    
