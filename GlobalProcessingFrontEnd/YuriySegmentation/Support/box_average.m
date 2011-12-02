function z = box_average(U,d)%diameter

mask = ones(round(d),round(d))/(round(d)*round(d));
z = conv2(U,mask,'same');

%correction
[w,h]=size(U);
norm_image = conv2(ones(w,h),mask,'same');
z = z./norm_image;

