data = csvread('results.csv');
data = data(1:numel(decay));
data = reshape(data,size(decay));

 
plot(data);
hold on
plot(decay,'o')
%ylim([10 1e5])
hold off

%plot(data ./ decay)