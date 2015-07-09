sz = size(data);

bg = repmat(background,[1 1 sz(3:4)]);
d= double(data) - bg;
d = reshape(d, [256 3 sz(3)*sz(4)]);

I = sum(d,1);
I = sum(I,2);
I = I(:);

sel = I < 500;

d = mean(d(:,:,sel),3) * (64/512)^2;
%d = d ./ repmat(max(d,[],1),[256, 1]);
clf
semilogy(d)

legend({'RFP','GFP','CFP'})

a = max(d,[],1)
a = a * 0.6717 / max(a)