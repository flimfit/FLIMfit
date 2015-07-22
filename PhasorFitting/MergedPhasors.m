
%FRETPhasor();

folder = [root '2015-07-08 MutRac dual cells/'];
folder = [root '2015-07-02 CFP-GFP cells/'];
folder = [root '2015-07-08 YFP mRFP cells/'];

folder = '/Volumes/Seagate Backup Plus Drive/FLIM Data/2015-07-16 Dual FRET mouse/';
files = dir([folder '01 Control*.pt3']);

folder = [root '2015-07-03 RhoRac dual mouse/'];
files = dir([folder '01*.pt3']);

pp = {}; II = {};

for i=1:length(files)
    
    filename = [folder files(i).name];

    [data, t] = LoadImage(filename);
    sz = size(data);

    [p, II{i}] = CalculatePhasor(t, data, irf_phasor, background);
    %{
    kern = fspecial('disk',3);
    p = reshape(p,sz(2:4));
    
    for j=1:size(p,1)
        p(j,:,:) = imfilter(squeeze(p(j,:,:)), kern, 'replicate');
    end
    %}
    pp{i} = reshape(p,[sz(2), sz(3)*sz(4)]);

    
    drawnow
end


%%

pt = [];
It = [];
for i=1:length(pp)
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
    %DrawPhasor(pp{i},II{i});
    %drawnow
    %pause(1)
end



figure(4)
clf

Is = sum(It,1);
sel = Is > 0;
DrawPhasor(pt(:,sel),It(:,sel))
ylim([0.3 0.6]);
xlim([0.2 0.8]);
%DrawPhasorTrajectories