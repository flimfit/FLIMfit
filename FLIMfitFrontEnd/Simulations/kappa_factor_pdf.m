function p = kappa_factor_pdf(f)

    p = (log(2 + sqrt(3)) - heaviside(f - 1) .* log(sqrt(f) + sqrt(f-1))) ./ (2 * sqrt(3 * f));
    p = p / sum(p);