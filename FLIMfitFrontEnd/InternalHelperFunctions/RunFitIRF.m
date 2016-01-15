function RunFitIRF(ax)
   
    if nargin < 1
        ax = axes();
    end

    [file, path] = uigetfile('*.csv');
    data = csvread([path file],0,0);

    t = data(:,1);
    d = data(:,2:end);

    sel = t < 12000;
    t = t(sel);
    d = d(sel,:);
   
    for i=1:size(d,2)
        irf(:,i) = FitIRF(t(sel),d(sel,i),ax);
    end
    
    plot(ax, t, irf);
    ylabel('IRF'); xlabel('Time (ps)');
   
    outfile = strrep([path file],'.csv','-irf.csv');
    csvwrite(outfile, [t(sel), irf]);
end