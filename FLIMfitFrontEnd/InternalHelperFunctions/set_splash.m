function set_splash(splash_image_filename)

try

% create a figure that is not visible yet, and has minimal titlebar properties
fh = figure('Visible','off','MenuBar','none','NumberTitle','off');

% put an axes in it
ah = axes('Parent',fh,'Visible','off');
ih = imshow(splash_image_filename);

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

catch err
    [ST,~] = dbstack('-completenames'); errordlg([err.message ' in the function ' ST.name],'Error');
end

end

