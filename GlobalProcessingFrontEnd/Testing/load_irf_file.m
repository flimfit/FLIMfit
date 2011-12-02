function [tirf,irf,name] = load_irf_file(file)

    if (nargin<1)
        % Get IRF data
        [tirf,irf_image_data,~,name] = open_flim_files('Select a file from the IRF data set');
    else
        [tirf,irf_image_data,~,name] = open_flim_files([],file);
    end
    
    irf_image_data = irf_image_data;
    
    % Sum over pixels
    irf = sum(sum(irf_image_data,3),2);
    
    irf = irf ./ norm(irf(:));
    
    % Pick out peak section of IRF (section of IRF within 20dB of peak)
    %[tirf,irf,background] = pickOutIRF(tirf,irf);
    
    % Remove 'background', set to minimum value of IRF
    %irf = irf - background;
    
    %scaleFactor = max(irfData)/max(irfFull);
    %plot(irfDel,irfFull.*scaleFactor,'r',irfTimes,irfData);

end