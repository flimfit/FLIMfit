function [histw, histv] = histwv(v, w, min, max, bins) 
%Inputs: 
%vv - values 
%ww - weights 
%minV - minimum value 
%maxV - max value 
%bins - number of bins (inclusive) 

%Outputs: 
%histw - wieghted histogram 
%histv (optional) - histogram of values 

delta = (max-min)/(bins-1); 
subs = round((v-min)/delta)+1; 

subs(subs > bins) = bins;
subs(subs < 1) = 1;
subs(~isfinite(subs)) = 1;

histv = accumarray(subs,1,[bins,1]); 
histw = accumarray(subs,w,[bins,1]); 
end