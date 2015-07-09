function PlotMerged(A,I,lim)

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
    
    limh = prctile(I(~isnan(I)),95);
    limh = 2;
    
    I = I / limh;
    I(I>1) = 1;
    I(isnan(I)) = 0;
    I = repmat(I,[1 1 3]);
    
    a = a .* I;
    
    h = size(A,1);
    w = round(size(A,2) * 0.1);
    cbar = round(linspace(m,1,h));
    Ibar = linspace(0.2,1,w);
    cbar = repmat(cbar',[1 w]);
    Ibar = repmat(Ibar,[h 1 3]);

    ccbar = c(cbar,:);
    ccbar = reshape(ccbar, [size(cbar), 3]) .* Ibar;
    
    a = [a ccbar];
    
    set(gca, 'Units', 'pixels')
    
    image(a);
    daspect([1 1 1]);
    text(4,7,num2str(limh,3),'Color','w','BackgroundColor','k','HorizontalAlignment','left','VerticalAlignment','top')
    text(size(A,2)-3,7,num2str(lim(2),2),'Color','w','BackgroundColor','k','HorizontalAlignment','right','VerticalAlignment','top')
    text(size(A,2)-3,size(A,1)-3,num2str(lim(1),3),'Color','w','BackgroundColor','k','HorizontalAlignment','right','VerticalAlignment','bottom')
    set(gca,'XTick',[],'YTick',[]);
    set(gca, 'Units', 'normalized');
    
end