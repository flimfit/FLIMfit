function c = convolve_irf(tirf, irf, t, model)

c = zeros(size(t));

for i=1:length(t)
   
    fi = model(-tirf+t(i));
    c(i) = fi*irf';
    
end

end
