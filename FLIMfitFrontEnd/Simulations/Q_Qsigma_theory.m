filters = csvread(['spectra' filesep 'filters.csv'],1,0);

%%
emission = csvread(['spectra' filesep 'normalised_emission.csv'],1,0);

%%
excitation = csvread(['spectra' filesep 'two_photon_excitation.csv'],1,0);

%%


w = excitation(:,1);
d = excitation(:,2:end);

ex = normpdf(w,840,5);

d_ex = d .* ex;

a = sum(d_ex);

plot(w,d);
hold on;
plot(w,100 * ex / max(ex),'k');
hold off;

sigma_rac = a(3) / a(1);
sigma_rho = a(4) / a(2);

%%

% https://www.fpbase.org/protein/ecfp/
% https://www.fpbase.org/protein/egfp/
% https://www.fpbase.org/protein/seyfp/
% https://www.fpbase.org/protein/mrfp1/

QY = [0.4 0.6 0.56 0.25]

w = filters(:,1);
e = emission(:,2:end);
f = filters(:,2:end);

filtered_emission = [];
for i=1:size(e,2)
    filtered_emission(:,i) = sum(e(:,i) .* f);
end

sum_filtered_emission = sum(filtered_emission,1);

Q_rac = sum_filtered_emission(3) / sum_filtered_emission(1) * QY(3) / QY(1)
Q_rho = sum_filtered_emission(4) / sum_filtered_emission(2) * QY(4) / QY(2)

Qsigma_rac = Q_rac * sigma_rac
Qsigma_rho = Q_rho * sigma_rho
