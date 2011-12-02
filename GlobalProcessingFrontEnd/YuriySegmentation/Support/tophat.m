function z = tophat(x,d)%diameter

z1 = x - box_average(x,d);
z2 = abs(z1);

z = (z1+z2)/2;






