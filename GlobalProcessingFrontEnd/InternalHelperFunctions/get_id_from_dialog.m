      function id = get_id_from_dialog(dlgTitle,prompt,defaultvalues)
            id = 0;
            numLines = 1;           
            while (id < 1) 
                inputdata = inputdlg(prompt,dlgTitle,numLines,defaultvalues);
                id = uint32(str2num(inputdata{1}));
            end            
        end