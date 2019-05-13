function L = membrane_stain(U, min_vol, max_vol, convex_area, convex_perim, int_in_cell, int_border)
%Segment cell membrane by edge detection and dilation
%min_vol=0,max_vol=100,convex_area=0.50,convex_perim=0.45,int_in_cell=1.35,int_border=1.2

% Smoothing
prm.smoothim.method = 'dirced';

% Ridge filtering
prm.filterridges = 1;

% Segmentation
prm.classifycells.convexarea = convex_area;
prm.classifycells.convexperim = convex_perim;
prm.classifycells.intincell = int_in_cell;
prm.classifycells.intborder = int_border;
[cellbw,wat,imsegmout,minima,minimacell,info] = cellsegm.segmsurf(U,min_vol,max_vol,'prm',prm);

L = bwlabel(cellbw);
kern = strel('disk',2);
L = imdilate(L,kern);

