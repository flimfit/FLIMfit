function a = is64()
    cmp = computer;
    a = all(cmp(end-1:end) == '64');
end