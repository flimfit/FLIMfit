%FRETPhasor();

k = linspace(0,2,10);
%k = [0 0.2 0.4 0.6 0.8 1 1.2 1.4];

p = zeros(length(k),3);
I = zeros(length(k),3);

otherK = 0.2;
otherA = 0;

pG = [];
pC = [];

for i=1:length(k)
    [pC(i,:),IC(i,:)] = FRETPhasor(1,otherA,k(i),otherK);
    [pG(i,:),IG(i,:)] = FRETPhasor(otherA,1,otherK,k(i));
end

c = [1 0 0;
     0 1 0;
     0 0 1];
%{
clf

subplot(2,1,1);
set(gca,'ColorOrder',c,'NextPlot','replacechildren')
%}

hold on
plot(pG,'x-');
hold on
plot(pC,'o-');

pc = 1./(1-1i*logspace(-10,10,1000));
plot(pc,'k')
ylim([0.3 0.6]);
xlim([0.2 0.8]);
daspect([1 1 1])

%{
subplot(2,1,2)
set(gca,'ColorOrder',c,'NextPlot','replacechildren')
hold on;
plot(E,IG)
plot(E,IC,'--')
%}