function moved = align_images(moving, fixed, display)

    if nargin < 3
        display = false;
    end
    
    [optimizer, metric] = imregconfig('multimodal');
    optimizer.MaximumIterations = 40;
    
    moved = moving;
    
    try
        t = imregtform(moving,fixed,'rigid',optimizer,metric);
        dx = t.T(3,1:2);
        dx = norm(dx);
        disp(dx);

        % Check we haven't moved too far; indicated failure to align
        if dx<200
            moved = imwarp(moving,t,'OutputView',imref2d(size(fixed)));
        end
    end
    
    if display
        figure(13);

        subplot(1,2,1)
        m = moving - min(moving(:));
        im(:,:,1) = m ./ max(m(:));
        im(:,:,2) = fixed ./ max(fixed(:));
        im(:,:,3) = 0;

        im(im<0) = 0;

        imagesc(im);
        daspect([1 1 1]);
        set(gca,'XTick',[],'YTick',[]);
        title('Before Alignment');


        subplot(1,2,2)
        m = moved - min(moved(:));
        im(:,:,1) = m ./ max(m(:));
        im(:,:,2) = fixed ./ max(fixed(:));
        im(:,:,3) = 0;

        im(im<0) = 0;

        imagesc(im);
        daspect([1 1 1]);
        set(gca,'XTick',[],'YTick',[]);
        title('After Alignment');
    end
end
