function fh = set_splash(splash_image_filename)

    % create a figure that is not visible yet, and has minimal titlebar properties
    fh = figure('Visible','off','MenuBar','none','NumberTitle','off');

    % put an axes in it
    ah = axes('Parent',fh,'Visible','off');
    dat = imread(splash_image_filename);
    ih = imagesc(dat); daspect([1,1,1]); set(ah,'XTick',[],'YTick',[]);

    % set the figure size to be just big enough for the image, and centered at
    % the center of the screen
    imxpos = get(ih,'XData');
    imypos = get(ih,'YData');
    set(ah,'Unit','Normalized','Position',[0,0,1,1]);
    figpos = get(fh,'Position');
    figpos(3:4) = [imxpos(2) imypos(2)];
    set(fh,'Position',figpos);
    movegui(fh,'center')

    % make the figure visible

    set(fh,'Visible','on');
    set(fh,'Name','Loading...');

    drawnow

end

