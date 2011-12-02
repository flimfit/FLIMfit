function z = membrane_segmetation(U, threshold_adjust, membrane_width)

U=imadjust(U, [0,0.05], [0,1]);
%figure, imshow(I), title('original image');

[~ threshold] = edge(U, 'sobel');
BWs = edge(U,'sobel', threshold * threshold_adjust);

se90 = strel('line', 3, 90);
se0 = strel('line', 3, 0);
BWsdil = imdilate(BWs, [se90 se0]);

BWdfill = imfill(BWsdil, 'holes');

BWnobord = imclearborder(BWdfill, 8);

seD = strel('diamond',1);
BWfinal = imerode(BWnobord,seD);
BWfinal = imerode(BWfinal,seD);

BWerode=bwmorph(BWfinal, 'erode', membrane_width);

BWdiff= BWfinal - BWerode;
BWdiff=im2uint16(BWdiff);%Change?

BWoutline = bwperim(BWdiff);
Segout = U;
Segout(BWoutline) = 32768;

BWdiff=BWdiff-65534; %Change??
Segmentedimage=immultiply(BWdiff,U);
figure, imshow(Segmentedimage), title('Membarne');