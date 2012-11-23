classdef h5writer < h5_serializer 
    
    properties
        a;
        b;
        c;
        d;
    end
    
    methods
       
        function obj = h5writer()
           
            obj.a = struct();
            obj.a.a1 = [1 2 3 4 5];
            obj.a.a2 = 'hello';
            obj.a.a3 = {'a' 'b' 'c' 'd'};
            
            obj.b = {'hello' 'my' 'name' 'is'};
            obj.c = magic(100);
            
            file = tempname;
            
            obj.serialize(file);
            
            obj.a = [];
            obj.b = [];
            obj.c = [];
            
            obj.deserialize(file);
            
            disp(obj.a);
            disp(obj.b);
            
%            s = obj.c - magic(100);
%            s = sum(s(:));
%            disp(s);
            
        end
        
    end
    
end