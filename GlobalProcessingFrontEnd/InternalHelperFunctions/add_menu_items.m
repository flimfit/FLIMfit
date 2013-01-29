function add_menu_items(menu,names,fcn,var)

    for i=1:length(names)
        uimenu(menu,'Label',names{i},'Callback',@(~,~)fcn(var{i}));
        %uimenu(menu,'Label',names{i});
    end  

end