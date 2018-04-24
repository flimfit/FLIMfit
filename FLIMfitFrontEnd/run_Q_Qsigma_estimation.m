
folder = '\\gagri\griw\InvasionAndMetastasis\Sean Warren\Bottleneck Sean\180419 - 172 CFP-YFP calibration\segmented_regions\';
irf_file = '\\gagri\griw\InvasionAndMetastasis\Sean Warren\Bottleneck Sean\180419 - 172 CFP-YFP calibration\analytical irf 2.json';

files = dir([folder '*.csv']);

clear results;

for i=1:length(files)

    reader = get_flim_reader([folder files(i).name]);

    t = reader.delays;
    data = reader.read([1 1 1],[1 2]);
    
    sel = t >= 500;
    t = t(sel);
    data = data(sel,:);

    json_data = fileread(irf_file);
    irf = jsondecode(json_data);
   
    results(i) = interactiveQ(t,data,irf);
    
end

results = struct2table(results);

%%


sel = results.E > 0.03;

r = results(sel,:);

figure(4)
colormap('copper')
scatter(r.Q,r.sigma,36,r.E,'x');
hold on;
colorbar
c = [mean(r.Q),mean(r.sigma)];

plot(c(1),c(2),'or');
xlabel('Q');
ylabel('sigma');
 
cv = cov([r.Q r.sigma]) / sqrt(height(r)-1);
error_ellipse(cv,'mu',c,'conf',0.95)
hold off;

