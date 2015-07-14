function in_ellipse = PhasorInEllipse(p, sel)

        p = p - sel.centre;
        in_ellipse = (real(p)/sel.r(1)).^2 + (imag(p)/sel.r(2)).^2 <= 1; 

end