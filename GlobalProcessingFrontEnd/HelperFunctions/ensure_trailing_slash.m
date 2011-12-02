function path = ensure_trailing_slash(path)
    if ~strcmp(path,filesep)
       path = [path filesep];
    end
end