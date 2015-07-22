function PlotMerged(AC,IC,lim,limI)
    
    if nargin < 4
        limI = nan;
    end

    A = [];
    I = [];
    
    
    if iscell(AC)
        sep = nan([size(AC{1},1),1]);
        for i=1:length(AC)
            A = [A sep AC{i}];
            I = [I sep IC{i}];
        end
        sz = size(AC{1});
    else
        A = AC;
        I = IC;
        sz = size(AC);
    end    
        

    m = 256;
    c = jet(m);
    
    A = (A - lim(1)) / (lim(2)-lim(1));
    A = A * (m-1) + 1;
    A = round(A);
    A(A<1) = 1;
    A(A>m) = m;
    A(isnan(A)) = 1;
    
    a = c(A,:);
    a = reshape(a, [size(A), 3]);
    
    if isnan(limI)
        limI = prctile(I(~isnan(I)),99);
    end
        
    I = I / limI;
    I(I>1) = 1;
    I(isnan(I)) = 0;
    I = repmat(I,[1 1 3]);
    
    a = a .* I;
        
    h = size(A,1);
    w = round(sz(2) * 0.1);
    cbar = round(linspace(m,1,h));
    Ibar = linspace(0.2,1,w);
    cbar = repmat(cbar',[1 w]);
    Ibar = repmat(Ibar,[h 1 3]);

    ccbar = c(cbar,:);
    ccbar = reshape(ccbar, [size(cbar), 3]) .* Ibar;
    
    a = [a ccbar];
    
    set(gca, 'Units', 'pixels')
    
    fs = 15;
    
    image(a);
    daspect([1 1 1]);
    text(4,7,num2str(limI,3),'FontSize',fs,'Color','w','BackgroundColor','k','HorizontalAlignment','left','VerticalAlignment','top')
    text(size(A,2)-3,7,num2str(lim(2),2),'FontSize',fs,'Color','w','BackgroundColor','k','HorizontalAlignment','right','VerticalAlignment','top')
    text(size(A,2)-3,size(A,1)-3,num2str(lim(1),3),'FontSize',fs,'Color','w','BackgroundColor','k','HorizontalAlignment','right','VerticalAlignment','bottom')
    set(gca,'XTick',[],'YTick',[]);
    set(gca, 'Units', 'normalized');
    
end