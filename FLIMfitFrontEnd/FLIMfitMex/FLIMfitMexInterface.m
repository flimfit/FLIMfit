function [varargout] = FLIMfitMexInterface(module,varargin)
    [msg,varargout{1:nargout}] = FLIMfitMex(module,varargin{:});
    if ~strcmp(msg,'OK')
        throw(MException('FLIMFit:mexError',msg));
    end
end