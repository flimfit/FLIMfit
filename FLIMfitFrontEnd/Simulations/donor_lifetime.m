function tau = donor_lifetime(D, i, kt)
    tau = 1 ./ (D.kf + D.knf(i) + kt);