function [x]=fdeconv(y, h)
%FDECONV Fast Deconvolution
%   [x] = FDECONV(y, h) deconvolves h out of y, and noramalizes the 
%         output to +-1.
%
%      y = input vector
%      h = input vector
%
%      See also DECONV
%
%   NOTES:
%
%   1) I have a short article explaining what a convolution is.  It
%      is available at http://stevem.us/fconv.html.
%
%
%Version 1.0
%Coded by: Stephen G. McGovern, 2003-2004.

Lx=length(y)-length(h)+1;  % 
Lx2=pow2(nextpow2(Lx));    % Find smallest power of 2 that is > Lx
Y=fft(y, Lx2);		   % Fast Fourier transform
H=fft(h, Lx2);		   % Fast Fourier transform
X=Y./H;        		   % 
x=real(ifft(X, Lx2));      % Inverse fast Fourier transform
x=x(1:1:Lx);               % Take just the first N elements
x=x/max(abs(x));           % Normalize the output


 