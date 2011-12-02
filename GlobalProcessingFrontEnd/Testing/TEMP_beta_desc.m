n_tau = 2;

d = cell(n_tau-1,n_tau);

for i=1:(n_tau-1)
    for j=i:n_tau
       
        if j<=i
            d{i,j} = [d{i,j} '1'];
        elseif (j<n_tau)
            d{i,j} = [d{i,j} '-alf' num2str(j-1)];
        else
            d{i,j} = [d{i,j} '-1'];
        end
        
        for k=1:(j-1)
           
            if k~=i
                d{i,j} = [d{i,j} '(1-alf' num2str(k-1) ')'];
            end
            
        end
        
    end 
end

d