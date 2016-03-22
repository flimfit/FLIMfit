function escaped_callback( ~, ~, fcn)
            
    if false && ~isdeployed
        fcn();
    else            
        try
            fcn();
        catch e
            d = getReport(e,'extended','hyperlinks','off');
            diagnostics('program','error','error_report',d);
            error_dialog2({d});
        end
    end

end