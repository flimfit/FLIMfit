function ret = parse_DIFN_format1(DelayedImageFileName)

% T_07000.tif

    str = split('_',DelayedImageFileName);                            
    str1 = char(str(length(str)));
    str2 = split('.',str1);
    
ret.delaystr = num2str(str2num(char(str2(1))));

end

