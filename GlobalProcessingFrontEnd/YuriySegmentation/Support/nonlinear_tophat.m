function z = nonlinear_tophat(U,d,K)

U1 = box_average(U,d);
U2 = box_average(U,K*d);

z = U.*U1./(U2.*U2);






