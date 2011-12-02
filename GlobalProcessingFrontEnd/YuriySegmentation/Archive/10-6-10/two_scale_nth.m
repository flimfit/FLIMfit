function z = two_scale_nth(U,S1,K1,S2,K2,t,smooth_scale,min_size)

se = strel('disk',smooth_scale);

nth1 = nonlinear_tophat(U,S1,K1)-1;
nth2 = nonlinear_tophat(U,S2,K2)-1;

%correction?
%c_1_2 = sqrt(S1/S2);
%if (c_1_2>1) 
%    nlth1 = nlth1*c_1_2;
%else
%    nlth2 = nlth2/c_1_2;
%end;

%nlth1 = nlth1/sqrt(S1);
%nlth2 = nlth2/sqrt(S2);

nth = pixelwise_max(nth1,nth2);
nth = (nth+abs(nth))/2;
b1 = im2bw(nth,t);
b2 = imerode(b1,se); b1 = imdilate(b2,se);

L = bwlabel(b1);
stats = regionprops(L,'Area');
idx = find([stats.Area] > min_size);
z = ismember(L,idx);
z = bwlabel(z);
