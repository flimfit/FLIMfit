function GenerateDetectorCorrection(file, sample)

    spectra.atto_425 = [1.5852    1.0000    0.7639];    
    spectra.atto_425_old = [0.9471;    1.0000;    0.1092];
    spectra.atto_488 = [];
    spectra.green_chromaslide = [0.351963498827600; 1; 0.185478295978306];

    ref_ch = 2;

    % Get file if not specified
    if nargin < 1
        [file, path] = uigetfile('*.*');
        if file == 0, return, end
        file = [path filesep file];
    end
    
    % Get sample type from user if not specified
    if nargin < 2 || ~isfield(spectra, sample)
        sample_types = fieldnames(spectra);
        
        [idx,tf] = listdlg('ListString',sample_types,'SelectionMode','single',...
                           'PromptString', 'Choose Sample Type');
                        
        if ~tf, return, end
        
        sample = sample_types{idx};    
    end
    
    ref_spectra = spectra.(sample);
    ref_spectra = reshape(ref_spectra,[1, 1, length(ref_spectra)]);
    
    % Read data
    settings.spatial_binning = 1;
    settings.temporal_downsampling = 0;
    settings.phase = 0;
    reader = flimreader_reader(file, settings);
    data = reader.read([1 1 1],[1 2 3]);
    I = squeeze(sum(data,1));
    I = permute(I,[2 3 1]);
    
    % Smooth data
    kern = fspecial('disk',4);
    for i=1:size(I,3)
        I(:,:,i) = imfilter(squeeze(I(:,:,i)),kern,'replicate','same');
    end
    
    I_ref = I(:,:,ref_ch);
    I_ref = nanmean(I_ref(:));
    
    % Normalise to reference channel and then reference sample
    correction = ref_spectra .* I_ref ./ I;
    %correction = correction .* ref_spectra;
    
    
    for i=1:size(correction,3)
        [~,fit] = FitZernike(correction(:,:,i));
        fit_correction(:,:,i) = fit;
    end 
    
    
    if any(~isfinite(correction(:)))
        warndlg('Correction image contained non-finite values');
    end
    
    % Display results
    figure
    for i=1:size(correction,3)
        subplot(1,size(correction,3),i)
        imagesc(squeeze(fit_correction(:,:,i)))

        %imagesc(squeeze(fit_correction(:,:,i) - correction(:,:,i)))
        daspect([1 1 1])
        %caxis([-0.5 0.5])
        colorbar
    end
    
    correction = permute(fit_correction,[2,1,3]);
    
    names = arrayfun(@(ch) ['Channel ' num2str(ch)], 1:size(correction,3), 'UniformOutput', false);
    description = 'Detector Correction File';
    
    [path,filename] = fileparts(file);
    output_file = [path filename '_detector_correction.tif'];
    
    SaveFPTiffStack(output_file, correction, names, description);

end