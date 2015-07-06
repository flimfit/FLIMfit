bg = repmat(background,[1 1 64 64]);
d= double(data)- bg;
d = reshape(d, [256 3 64*64]);

I = sum(d,1);
I = sum(I,2);
I = I(:);

sel = I > 50000;

d = mean(d(:,:,sel),3) * (64/512)^2;
d = d ./ max(d,[],1);
clf
semilogy(d)

legend({'RFP','GFP','CFP'})

a = max(d,[],1)
a = a * 0.4433 / max(a)