function escaped_callback( ~, ~, fcn)
            
    if false && ~isdeployed
        fcn();
    else            
        try
            fcn();
        catch e
            d = getReport(e,'extended','hyperlinks','off');
            diagnostics('program','error','error_report',d);
            d = ['An error occurred - please file a bug using the bug tracker in the Help menu providing information about when this error occurred and a screenshot of this message.' char(10) char(10) d];
            errordlg(d,'Error Occurred');
        end
    end

end