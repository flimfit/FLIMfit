function ProcessFLIMFolder(folder)

    FRETPhasor;

    if nargin < 1
        folder = uigetdir();
    end
    
    irf_file = FindFile(folder, '*-irf', '.csv', 'IRF');
    background_file = FindFile(folder, 'data-background', '.pt3', 'Background');
    
    irf_phasor = GetIRFPhasor(irf_file);
    background = GetBackground(background_file);
    
    files = dir([folder filesep '*.pt3']);
    
    for i=1:length(files)
        % only process numbered files
        if ~isnan(str2double(files(i).name(1:2)))
            file = [folder filesep files(i).name];
            ProcessFLIMImage(file, irf_phasor, background, '');
        end
    end
        
end