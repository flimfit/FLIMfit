function generate_segmentation_functions_file()
    folder = [pwd filesep 'SegmentationFunctions'];
    addpath(folder);
    addpath([folder filesep 'Support']);

    [funcs, param_list, default_list, desc_list summary_list] = parse_function_folder(folder);

    save('segmentation_funcs.mat', 'funcs', 'param_list', 'default_list', 'desc_list', 'summary_list');
end