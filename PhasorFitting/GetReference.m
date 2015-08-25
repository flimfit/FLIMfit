function [reference, t] = GetReference(ax)

    [file, folder] = uigetfile('*.pt3', 'Select the reference file');
    reference_file = [folder filesep file];
    
    [file, folder] = uigetfile('*.pt3', 'Select the reference background file', folder);
    background_file = [folder filesep file];
    
    [reference, t] = LoadImage(reference_file); 
    [ref_background] = LoadImage(background_file); 

    sz = size(reference);
    reference = reshape(reference,[sz(1:2) prod(sz(3:4))]);
    reference = mean(reference,3);

    ref_background = reshape(ref_background,[sz(1:2) prod(sz(3:4))]);
    ref_background = mean(double(ref_background),3);

    reference = reference - ref_background;
    
    output_filename = strrep(reference_file, '.pt3', '-reference.csv');
    csvwrite(output_filename,[t, reference]);
    
    if nargin > 0
        plot(ax, t, reference);
        ylabel('Itensity'); xlabel('Time (ps)');
    end
end