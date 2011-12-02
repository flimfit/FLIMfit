f = fopen('c:\users\scw09\varp2_export.dat');
g_size = 100;
n_d = 100;
a = fread(f,g_size*g_size*n_d*2,'double');
fclose(f);
a = reshape(a,[g_size g_size 2 n_d]);

a(abs(a)>1e4) = NaN;

a = a(:,:,1,:);
a = squeeze(a);