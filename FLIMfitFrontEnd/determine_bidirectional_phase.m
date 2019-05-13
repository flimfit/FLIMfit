function phase = determine_bidirectional_phase(im)


    im1 = im(:,1:2:end);
    im2 = im(:,2:2:end);

    im2 = flipud(im2);

    figure(110)

    imagesc([im1,im2]);
    daspect([1 1 1])

    tform = imregcorr(im1,im2,'translation');
    phase = tform.T(3,2);
    assert(abs(tform.T(3,1))<2);

    im2w = imwarp(im1,imref2d(size(im1)),tform);

    imf = im;
    imf(:,2:2:end) = im2w;

    imagesc(imf);