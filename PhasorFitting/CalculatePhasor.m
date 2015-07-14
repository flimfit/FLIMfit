function [p,I] = CalculatePhasor(t, data, irf_phasor, background)

    data = double(data);
    sz = size(data);

    if nargin < 3
        irf_phasor = 1;
    end
    if nargin == 4
        data = data - repmat(background,[1 1 sz(3:4)]);
    end

    n_channel = size(data,2);

    T = 12500;
    omega = 2*pi/T;

    n = prod(sz(2:end));
    d = reshape(data, [sz(1), n]);
    c = repmat(exp(1i * omega * t),[1 n]);

    I = sum(d,1);

    p = sum(d.*c,1) ./ I;

    p = reshape(p,n_channel,n/n_channel);
    I = reshape(I,n_channel,n/n_channel);

    % Subtract IRF
    pir = repmat(irf_phasor, [1, size(p,2)]);
    p = p ./ pir;
    
end