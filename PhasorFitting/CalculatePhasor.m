function [p,I] = CalculatePhasor(t, data, irf_phasor)

    T = 12500;
    omega = 2*pi/T;


    sz = size(data);
    n = prod(sz(2:end));
    d = reshape(data, [sz(1), n]);
    d = double(d);
    c = repmat(exp(1i * omega * t),[1 n]);

    I = sum(d,1);

    p = sum(d.*c) ./ I;

    p = reshape(p,2,n/2);
    I = reshape(I,2,n/2);

    % Subtract IRF
    pir = repmat(irf_phasor, [1, size(p,2)]);
    p = p ./ pir;
    
end