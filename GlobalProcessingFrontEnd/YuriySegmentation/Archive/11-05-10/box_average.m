function z = box_average(U,d)%diameter

mask = ones(d,d)/(d*d);
z = conv2(U,mask,'same');

%correction is below
r = round(max(1,d/2));

[w,h]=size(U);

for x=1:w,
    for y=1:h,
        if(x<=r || x>=w-r || y<=r || y>=h-r)
            num_pixs = 0;
            sum_pixs = 0;
            for i=-r:r, 
                for k = -r:r,
                  x_ = x+i;
                  y_ = y+k;
                  if x_>=1 && x_<=w && y_>=1 && y_<=h
                      num_pixs = num_pixs + 1;
                      sum_pixs = sum_pixs + U(x_,y_);
                  end;
                end; 
            end;
            z(x,y) = sum_pixs/num_pixs;
        end;
    end
end






