function irf = estimate_irf(t,decay)

    global fh_ei;
    
    if isempty(fh_ei)
        fh_ei = figure();
    else
        figure(fh_ei);
    end
    
    decay = decay - min(decay);
    
    sel = decay>0;
decay = decay(sel);
t = t(sel);
    

cum_decay = cumsum(decay);
cum_decay = cum_decay / cum_decay(end);

edge02 = find(cum_decay >  0.02,1,'first');
edge98 = find(cum_decay >= 0.98,1,'first');

centre = mean(decay .* t) / mean(decay);
width  = t(edge98) - t(edge02);
round  = 150;
slope  = 0.05;

tau1   = 400;
tau2   = 2000;
a1     = 0.9;

width = 150;

edge95 = find(cum_decay >= 0.90,1,'first');
tail_decay = decay(edge95:end);
tail_decay = tail_decay / tail_decay(1);
tail_t = t(edge95:end);
tail_t = tail_t - tail_t(1);

subplot(1,1,1);
plot(decay);

fminsearch(@exp_objt,[tau1 tau2 a1]);

function r = exp_objt(m)
   
    tau1 = m(1);
    tau2 = m(2);
    a1 = m(3);
    
    dc = a1 * exp(-tail_t/tau1)+ (1-a1) * exp(-tail_t/tau2);
    
    r = norm(tail_decay-dc);
    
end




nt = length(t);


%x0 = [centre width round tau1 tau2 a1 slope];
x0 = [centre width tau1 tau2 a1];
%x0 = [1540 2100 150 80 2700 0.99];

opt = optimset('MaxFunEvals',10000);
x = fminsearch(@(x)objt(x,false), x0,opt);

disp(['Centre = ' num2str(x(1)) ]);
disp(['Width = ' num2str(x(2)) ]);
%disp(x(3));
disp(['Tau = ' num2str(x(3:4))]);
disp(['A = ' num2str(x(5))]);

[r irf] = objt(x,true);

folder = getpref('GlobalAnalysisFrontEnd','DefaultFolder');

dlmwrite([folder '\est_irf.txt'],[t irf],'\t');


function [rn irf] = objt(x,disp)
   
    centre = x(1);
    width = x(2);
    
    %round = x(3);
    tau1 = x(3);   %x(4);
    tau2 = x(4); %x(5);
    a1 = x(5); %x(6);
    
%    slope = x(7);
    
    round = 0;
    slope = 0;

    irf = make_irf(centre,width,round,slope);
       
    d1 = a1 * cv(tau1,irf) + (1-a1) * cv(tau2,irf);
    
    w = sqrt(decay);
    w(w==0) = 1;
    w = 1./w;
    
    decayn = decay/sum(decay);
    d1 = d1/sum(d1);
    
    r = (decayn - d1);
    r = r(1:end);
    w = w(1:end);
    
    rn = sum(r.*r.*w);
    
    if disp
    subplot(1,3,1)
    plot(t,[d1 decayn irf]);
    %ylim([0 0.02]);
    xlabel('t (ps)');
    title('Linear Scale')
    subplot(1,3,2)
    semilogy(t,[d1 decayn irf]);
    %ylim([1e-4 0.06]);
    title('Log Scale')
    xlabel('t (ps)');
    legend({'Estimated Decay' 'Measured Decay' 'Computed IRF'})
    subplot(1,3,3)
    plot(r);
    drawnow
    end
    
end

function irf = make_irf(centre,width,round,slope)

    %{
irf = zeros(size(t));
irf(t>centre-width/2 & t<centre+width/2) = 1;

irf = irf .* ( 1 - ((t-centre).^2./centre^2)*slope );


irf_spacing = t(2) - t(1);

tk = -(round*5):irf_spacing:(round*5);
kern = normpdf(tk,0,round);
irf = conv(irf,kern,'same');
%}
   
irf = normpdf(t,centre,width);
    
irf = irf/sum(irf);

end

function decayc = cv(tau,irf)
       
    decayx = exp(-t/tau);
    
    decayc = conv(irf,decayx);
    decayc = decayc(1:nt);
    
%    decayc = decayc/sum(decayc);
end


end