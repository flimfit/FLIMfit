function z = pixelwise_min(U1,U2)

[w,h]=size (U1);

z = zeros(w,h);

for x=1:w, for y=1:h, 
        z(x,y) = min(U1(x,y),U2(x,y)); 
end; end;
        



