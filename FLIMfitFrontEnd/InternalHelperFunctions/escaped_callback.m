function escaped_callback(fcn,varargin)
            
    if ~isdeployed
        fcn(varargin{:});
    else            
        try
            fcn(varargin{:});
        catch e
            d = getReport(e,'extended','hyperlinks','off');
            bug_snag(e);
            clipboard('copy',d);
            error_dialog2({d});
        end
    end

end