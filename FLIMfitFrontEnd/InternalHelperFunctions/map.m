function z=map(x,ymin,ymax)

xmin = min(min(x));
xmax = max(max(x));

z = ymin+(x-xmin)*(ymax-ymin)/(xmax-xmin);







