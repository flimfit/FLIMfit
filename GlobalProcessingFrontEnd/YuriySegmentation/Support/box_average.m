function z = box_average(U,d)%diameter


r = round(d);
mask1 = ones(1,r)/r;
mask2 = mask1';

%mask = ones(r,r)/(r*r);

z = conv2(U,mask1,'same');
z = conv2(z,mask2,'same');
%z = conv2(U,mask,'same');

%correction
[w,h]=size(U);
%norm_image = conv2(ones(w,h),mask,'same');

norm_image = conv2(ones(w,h),mask1,'same');
norm_image = conv2(norm_image,mask2,'same');

z = z./norm_image;
