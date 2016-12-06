function escaped_callback( ~, ~, fcn)
            
    if strcmp(computer,'MACI64') && ~isdeployed
        fcn();
    else            
        try
            fcn();
        catch e
            d = getReport(e,'extended','hyperlinks','off');
            bug_snag(e);
            clipboard('copy',d);
            error_dialog2({d});
        end
    end

end