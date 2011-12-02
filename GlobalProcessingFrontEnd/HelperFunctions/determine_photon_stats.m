function [counts_per_photon offset] = determine_photon_stats(data)

    o = fminsearch(@objt,[1 0],options);

    counts_per_photon = o(1);
    offset = o(2);
    
    function r = objt(m) 

        tr = (data/m(1)-m(2));
        antr = 2*sqrt(tr+3/8);
        s = std(antr,0,2);
        r = norm(s-1);
    end

end

