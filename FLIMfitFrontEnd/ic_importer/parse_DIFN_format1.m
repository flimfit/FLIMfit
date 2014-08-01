       function ret = parse_DIFN_format1(DelayedImageFileName)

        ret = [];

            try

                str = split(' ',DelayedImageFileName);                            

                if 1 == numel(str)

                    str1 = split('_',DelayedImageFileName);                            
                    str2 = char(str1(2));
                    str3 = split('.',str2);
                        ret.delaystr = num2str(str2num(char(str3(1))));    

                elseif 2 == numel(str)

                     str = split(' ',DelayedImageFileName);                            
                     str1 = char(str(2));     
                     str2 = split('_',str1);                            
                     str3 = char(str2(2));
                     str4 = split('.',str3);
                        ret.delaystr = num2str(str2num(char(str4(1))));
                     str5 = split('_',char(str(1)));
                        ret.integrationtimestr = num2str(str2num(char(str5(2))));                
                end

            catch err
                disp(err.message);
            end
        end