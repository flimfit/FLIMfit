function p = kappa_factor_pdf(f)

    %p = (log(2 + sqrt(3)) - heaviside(f - 1) .* log(sqrt(f) + sqrt(f-1))) ./ (2 * sqrt(3 * f));
    %p = p / sum(p);
    
    % Accounting for integral
    df = f(2)-f(1);
    p = log(2 + sqrt(3)) / sqrt(3) * (sqrt(f+df) - sqrt(f));
    p = p - heaviside(f - 1) .* ((sqrt(f+df).*log(sqrt(f+df)+sqrt(f+df-1))-sqrt(f+df-1)) - ...
                             (sqrt(f).*log(sqrt(f)+sqrt(f-1))-sqrt(f-1))) / sqrt(3);
    