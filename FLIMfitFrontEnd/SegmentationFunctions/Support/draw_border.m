function z = draw_border(U,d,val)

z = U;
[w,h]=size(z);
for x=1:w,
    for y=1:h,
        if(x<=d || x>=w-d)
            z(x,y)=val;
        end
        if(y<=d || y>=h-d)
            z(x,y)=val;            
        end        
    end
end







