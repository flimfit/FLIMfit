% From this paper:
% http://onlinelibrary.wiley.com/doi/10.1002/cyto.990090617/pdf

dat = csvread('C:\Users\scw09\Documents\00 Local FLIM Data\2012-09-05 Ras-Raf Anca plate\hist\histograms.csv',1,0);

x = dat(:,1);
dat = dat(:,2:end);

control = dat(:,1);
dat = dat(:,2:end);

control = control / sum(control);
dat = dat ./ sum(dat,1);

n = size(dat,1);

mpd=[];

for i=2:n
    c = sum(control(i:end));
    d = sum(dat(i:end,:),1);
    
    mpd(i-1,:) = d-c;
end

plot(mpd)
legend({'1' '2' '3' '4' '5'})
