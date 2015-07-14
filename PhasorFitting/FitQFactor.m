folder = [root '2015-07-02 CFP-GFP cells/'];
files = dir([folder '2 *.pt3']);

xf = [];

for i=1:length(files) 
   
    filename = [folder files(i).name];
    
    [data, t] = LoadImage(filename);
    sz = size(data);
        
    [p, I] = CalculatePhasor(t, data, irf_phasor, background);
    

    p = double(p);
    I = double(I);

    n = size(p,2);

    Af = zeros([2,n]);
    kf = zeros([2,n]);
    rf = zeros([1,n]);

    sel = sum(I,1) > 1000;


    pf = p(:,sel);
    If = I(:,sel);

    xf(:,i) = FRETPhasor(mean(pf,2), mean(If,2), 'x');
end


xf
