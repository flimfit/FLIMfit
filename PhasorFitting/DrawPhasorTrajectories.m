%FRETPhasor();

k = linspace(0,1,10);
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
 
 
%%


%%
 

clf

set(gca,'ColorOrder',c,'NextPlot','replacechildren')


hold on
plot(pG,'o-');
hold on
plot(pC,'x-');

pc = 1./(1-1i*logspace(-10,10,1000));
plot(pc,'k')
ylim([0.3 0.6]);
xlim([0.2 0.8]);
xlim([0.8 1]);
ylim([0.2 0.38])
daspect([1 1 1])

%{
subplot(2,1,2)
set(gca,'ColorOrder',c,'NextPlot','replacechildren')
hold on;
plot(E,IG)
plot(E,IC,'--')
%}

return
%%

 
sel = k > 0.01;

%p1 = pC(1,3);
%p2 = 0.549 + 0.4392*1i;

p1 = pG(1,2);
p2 = 0.5098 + 0.4706*1i;


dp = p2 - p1; 

p0 = pG(sel,2);

d = imag(dp)*real(p0) - real(dp)*imag(p0) + real(p2)*imag(p1) - imag(p2)*real(p1);
d = abs(d) ./ abs(dp);

[~,idx] = min(d);
kk = k(sel);
kk(idx)

kk(idx)/(1+kk(idx))

figure(5)
plot(kk,d)
