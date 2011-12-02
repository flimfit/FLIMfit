function z = call_arb_segmentation_function(func,U,params)

    f = eval(['@' func]);
    z = feval(f,U,params);

end