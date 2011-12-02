function zl = membrane_segmentation(U, edge_sensitivity, membrane_width, area_thresh, solidity_thresh)

%U=imadjust(U, [min(U(:)),max(U(:))], [0,1]);
%figure, imshow(I), title('original image');

[junk threshold] = edge(U, 'sobel');
BWs = edge(U,'sobel', threshold * edge_sensitivity);
%figure, imshow(BWs), title('binary gradient mask');

se90 = strel('line', 3, 90);
se0 = strel('line', 3, 0);
BWsdil = imdilate(BWs, [se90 se0]);
%imshow(BWsdil), title('dilated gradient mask');

BWdfill = imfill(BWsdil, 'holes');
%imshow(BWdfill), title('binary image with filled holes');

BWnobord = imclearborder(BWdfill, 8);
%imshow(BWnobord), title('cleared border image');

seD = strel('diamond',1);
BWfinal = imerode(BWnobord,seD);
BWfinal = imerode(BWfinal,seD);
%imshow(BWfinal), title('segmented image');

BWerode=bwmorph(BWfinal, 'erode', membrane_width);
%imshow(BWerode), title('erode');


z = BWfinal - BWerode;

zl = bwlabel(z,4);

if max(z(:)) > 0
stats = regionprops(zl,{'Area','Solidity'});
s = cell2mat(struct2cell(stats));

area = s(1,:);
solidity = s(2,:);

filt = area > area_thresh & solidity < solidity_thresh;

for i=1:length(area)
    if ~filt(i)
        z(zl==i) = 0;
    end
end

zl = bwlabel(z,4);
else
    zl = z;
end

%z=im2uint16(z);%Change?

%{
BWoutline = bwperim(z);
Segout = U;
Segout(BWoutline) = 32768;
%}


%z=z-65534; %Change??

%imagesc(zl)
%max(zl)

%Segmentedimage=immultiply(BWdiff,U);
%figure, imshow(Segmentedimage), title('Membarne');