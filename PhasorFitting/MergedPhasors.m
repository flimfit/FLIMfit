
FRETPhasor();

folder = [root '2015-07-08 MutRac dual cells/'];
folder = [root '2015-07-02 CFP-GFP cells/'];
%folder = [root '2015-07-08 YFP mRFP cells/'];

files = dir([folder '4*.pt3']);


pp = {}; II = {};

for i=1:length(files)
    
    filename = [folder files(i).name];

    [data, t] = LoadImage(filename);
    sz = size(data);

    [pp{i}, II{i}] = CalculatePhasor(t, data, irf_phasor, background);
    drawnow
end


%%

pt = [];
It = [];
for i=1:length(pp); 
    pt = [pt pp{i}];
    It = [It II{i}];
    %{
    figure(1);
    f = I{i}(1,:) ./ I{i}(2,:);
    f = reshape(f,[256 256]);
    subplot(2,1,1)
    II = reshape(I{i}(1,:),[256,256]);    
    imagesc(f)
    
    colorbar
    %}
    DrawPhasor(pp{i},II{i});
    drawnow
    pause(1)
end


%%
figure(4)
clf

II = sum(It,1);
sel = II > 1000;
DrawPhasor(pt(:,sel),It(:,sel))
ylim([0.3 0.6]);
xlim([0.2 0.8]);
DrawPhasorTrajectories