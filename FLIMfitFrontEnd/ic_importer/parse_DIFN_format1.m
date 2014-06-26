       function ret = parse_DIFN_format1(DelayedImageFileName)

        ret = [];

            try

                str = strsplit(DelayedImageFileName,' ');                            

                if 1 == numel(str)

                    str1 = strsplit(DelayedImageFileName,' ');                            
                    str2 = char(str1(2));
                    str3 = strsplit(str2'.');
                        ret.delaystr = num2str(str2num(char(str3(1))));    

                elseif 2 == numel(str)

                     str = strsplit(DelayedImageFileName,' ');                            
                     str1 = char(str(2));     
                     str2 = strsplit(str1,'_');                            
                     str3 = char(str2(2));
                     str4 = strsplit(str3,'.');
                        ret.delaystr = num2str(str2num(char(str4(1))));
                     str5 = strsplit(char(str(1)),'_');
                        ret.integrationtimestr = num2str(str2num(char(str5(2))));                
                end

            catch err
                disp(err.message);
            end
        end