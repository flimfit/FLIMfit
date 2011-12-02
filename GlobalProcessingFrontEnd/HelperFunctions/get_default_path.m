function default_path = get_default_path()

    try
        default_path = getpref('GlobalAnalysisFrontEnd','DefaultFolder');
    catch %#ok
        addpref('GlobalAnalysisFrontEnd','DefaultFolder','C:\')
        default_path = 'C:\';
    end

end