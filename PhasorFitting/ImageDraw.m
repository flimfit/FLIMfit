function ImageDraw(folder, filter)

files = dir([folder, '*' filter '.mat']);

fh = figure(20);
set(fh, 'Name', 'Image Segmentation', 'NumberTitle', 'off');
r = 2;
cur_image = 1;
mouse_down = false;
mask = [];
im = [];
X = []; Y = [];
imh = [];
cur_region = 1;

displayImage();

axh = gca();
set(fh, 'WindowButtonMotionFcn', @mouseMove);
set(fh, 'WindowButtonDownFcn', @mouseDown);
set(fh, 'WindowButtonUpFcn', @mouseUp);
set(fh, 'KeyPressFcn', @keyPress);

    function displayImage()

        results = load([folder files(cur_image).name]);
                
        maskName()
        
        I = results.r.Isum;
        
        if exist(maskName(),'file')
            mask = imread(maskName());
        else
            mask = zeros(size(I),'uint8');
        end

        
        im = uint8([]);
        
        scaled = I / prctile(I(:),99);
        scaled(scaled>1) = 1;
        scaled(scaled<0) = 0;
        
        im(:,:,1) = uint8(scaled * 255);
        im(im>255) = 255;
        im(:,:,2) = (mask==1) * 128;
        im(:,:,3) = (mask==2) * 200;

        mouse_down = false;
        [X,Y] = meshgrid(1:size(im,2),1:size(im,1));

        imh = image(im);
        set(gca,'XTick',[],'YTick',[]);
        daspect([1 1 1])
        tightfig();
        
        displayNum();
        
    end

    function saveImage()
        imwrite(mask,maskName());
    end


    
    function mouseMove (~,~)
        if mouse_down
            
            C = get(axh, 'CurrentPoint');
            sel = (Y-C(1,2)).^2 + (X-C(1,1)).^2 < r^2;
            
            mode = strcmp(get(gcf,'SelectionType'),'normal');
            mask(sel) = mode * cur_region;
            
            im(:,:,2) = (mask==1) * 128;
            im(:,:,3) = (mask==2) * 200;
            set(imh,'CData',im);
        end
    end

    function keyPress(~,data)
       set(fh,'Pointer','crosshair')
        switch data.Key
           case 'rightarrow'
               saveImage();
               cur_image = mod(cur_image - 2, length(files)) + 1;
               displayImage();
           case 'leftarrow'
               saveImage();
               cur_image = mod(cur_image, length(files)) + 1;
               displayImage();
           case 'downarrow'
               r = r - 1;
               disp(r);
           case 'uparrow'
               r = r + 1;
               disp(r);
           case 'c'
               mask(:,:) = 0;
               im(:,:,2) = 0;
               set(imh,'CData',im);
           case '1'
               cur_region = 1;
           case '2'
               cur_region = 2;
           case '3'
               cur_region = 3;
       end     
       
    end

    function mouseDown(~,~)
        mouse_down = true;
    end

    function mouseUp(~,~)
        mouse_down = false;
        displayNum();
    end

    function displayNum()
       
        
        L = bwlabel(mask == 1);
        n1 = max(L(:));
        L = bwlabel(mask == 2);
        n2 = max(L(:));
        
        set(fh,'Name',['#1 = ' num2str(n1) ', #2 = ' num2str(n2)]);
        
    end

    function name = maskName()
        name = strrep([folder files(cur_image).name], '.mat', '.png');
    end

end

