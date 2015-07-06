function phasor = GetIRFPhasor(file)

    dat = csvread(file);
    t_irf = dat(:,1);
    irf = dat(:,2:end);
    phasor = CalculatePhasor(t_irf, irf, 1);

end