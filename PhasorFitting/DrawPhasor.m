function DrawPhasor(p,I)

    global red_sel
   
    if ~isfield(red_sel,'pos')
        red_sel.pos = [0 0 1 1];
    end
    
    ch = 1;

    %subplot(2,1,1)

    edges = linspace(0,1,256);

    n = [];
    for i=1:size(p,1)
        pc = [imag(p(i,:)); real(p(i,:))]';
        
        %ni = hist2w(pc,I(i,:),edges,edges);
        ni = histwv2(pc,I(i,:),0,1,256);
        %ni = hist3(pc,{edges,edges});
        ni = ni(2:255,2:255);
        n(:,:,i) = ni; % / prctile(ni(:),99.9);
    end
    
    n = n / prctile(ni(:),99.995);
    
    ed = edges(2:255);

    imagesc(ed,ed,n);
    daspect([1 1 1])
    set(gca,'YDir','normal')

    hold on;
    theta = linspace(0,pi,1000);
    c = 0.5*(cos(theta) + 1i * sin(theta)) + 0.5;
    plot(real(c), imag(c) ,'w');
    hold off;
    
    return 
    
    h = imellipse(gca,red_sel.pos);
    addNewPositionCallback(h, @callback)
    
    subplot(2,1,2)
    ax = gca;
    n = size(I,2);
    n2 = sqrt(n);
    Is = reshape(I,[size(I,1), n2,n2]);
    
    Is = p(ch,:,:);
    Is = real(Is)./imag(Is) * 12500/(2*pi);
    Is = reshape(Is, [n2,n2]);
    
    %I1 = squeeze(Is(ch,:,:));
    mx = max(Is(:));
    size(Is)
    
    
    callback(red_sel.pos);
    
    function callback(pos)
        centre = (pos(1) + pos(3)/2) + 1i* (pos(2) + pos(4)/2);
        r = [ pos(3)/2, pos(4)/2 ];
        
        red_sel.centre = centre;
        red_sel.r = r;
        red_sel.pos = pos;
        
        p1 = p(ch,:) - centre;
        sel = (real(p1)/r(1)).^2 + (imag(p1)/r(2)).^2 <= 1; 
        
        sel = reshape(sel,[n2 n2]);
        imagesc(sel .* Is, 'Parent', ax);
        daspect(ax,[1 1 1]);
        set(ax,'XTick',[],'YTick',[]);
        caxis(ax,[0 3000]);
    end
    
end