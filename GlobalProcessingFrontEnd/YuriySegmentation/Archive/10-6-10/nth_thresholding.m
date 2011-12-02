% U - an original grayscale image
% S - chatracteristic scale
% t - sensitivity threshold
function z = nth_thresholding(U,S,K,t,min_size)

smooth_scale = round(max(1,S/8));%voluntarism
se = strel('disk',smooth_scale);

% nonlinear tophat + otsu thersholded
nlth = nonlinear_tophat(U,S,K)-1;
nlth = (nlth+abs(nlth))/2;
BW = im2bw(nlth,t);
b1 = imerode(BW,se); b2 = imdilate(b1,se);
b2 = draw_border(b2,S,0);

%z = b2;

L = bwlabel(b2);
stats = regionprops(L, 'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);




