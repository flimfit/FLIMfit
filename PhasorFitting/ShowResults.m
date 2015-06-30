

files = dir([folder '*.mat']);


for i=1:length(files)
   
    load([folder files(i).name]);
   
    results{i} = r;
    names{i} = files(i).name;
    
end

sel = strfind(names, 'Post');
sel = cellfun(@isempty,sel);

results = results(sel);
names = names(sel);

names = strrep(names, '.pt3.mat', '');

%%

   
lim1 = [0.3 0.6];
lim2 = [0.3 0.7];


q = 6;
off = 6;
for i=1:q
    
    r = results{i+off};
    
    
    subplot(2,q,i);
    imagesc(r.E_CFP);
    PlotMerged(r.E_CFP, r.A_CFP, lim1)
    title(names{i+off}, 'Interpreter', 'none');

    subplot(2,q,i+q);
    imagesc(r.E_GFP);
    PlotMerged(r.E_GFP, r.A_GFP, lim2);
    title('GFP')
    %{
    edges{1} = linspace(0,1,256);
    edges{2} = edges{1};
    n1 = hist3([r.E_CFP(:) r.E_GFP(:)],edges);
    imagesc(edges{1},edges{2},log10(n1));
    daspect([1 1 1])
    set(gca,'YDir','normal')
    colorbar
%}
    
end