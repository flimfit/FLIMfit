function [coeff, fit] = FitZernike(im1,im2)

    sz = size(im1);
    nel = numel(im1);

    [X,Y] = meshgrid(linspace(-1,1,size(im1,2)),linspace(-1,1,size(im1,1)));

    theta = atan2(Y,X);
    rho = sqrt(X.^2+Y.^2);
    sin_theta = sin(theta);
    cos_theta = cos(theta);
    sin_2theta = sin(2 * theta);
    cos_2theta = cos(2 * theta);
    sin_3theta = sin(3 * theta);
    cos_3theta = cos(3 * theta);

    z(:,:,1) = ones(size(rho));
    z(:,:,2) = 2*rho.*sin_theta;
    z(:,:,3) = 2*rho.*cos_theta;

    
    z(:,:,4) = sqrt(6) * rho.^2 .* sin_2theta;
    z(:,:,5) = sqrt(3) * (2.0 * rho.^2 - 1.0);
    z(:,:,6) = sqrt(6) * rho.^2 .* cos_2theta;
    
    
    rho3 = rho.^3;
    z(:,:,7) = sqrt(8) * rho3 .* sin_3theta;
    z(:,:,8) = sqrt(8) * (3*rho3-2*rho) .* sin_theta;
    z(:,:,9) = sqrt(8) * (3*rho3-2*rho) .* cos_theta;
    z(:,:,10) = sqrt(8) * rho3 .* cos_3theta;
    
    z = z(:,:,[1,3]);
    
    x0 = zeros(1,size(z,3));
    %x0(1) = 1e-2;    
    %x0(2:3) = 1e-6;
    
    %x0(7:10) = 1e-9;
    
    opts = optimset('MaxFunEvals',500 * length(x0));
    coeff = fminsearch(@opt,x0,opts);
    
    coeff(1) = 1 + coeff(1);
    coeff = reshape(coeff,[1 1 length(coeff)]);
    fit = z .* coeff;
    fit = sum(fit,3);
    fit = fit;
    
    
    function r = opt(coeff)
        coeff(1) = 1 + coeff(1);
        coeff = reshape(coeff,[1 1 length(coeff)]);
        fitr = z .* coeff;
        fitr = sum(fitr,3);
        r = (fitr .* im2 - im1);
        r = r.^2;
        r = nansum(r(:));
    end
end