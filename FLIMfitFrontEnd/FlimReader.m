function [varargout] = FlimReader(varargin)
    [msg,varargout{1:nargout}] = FlimReaderMex(varargin{:});
    if ~strcmp(msg,'OK')
        throw(MException('FlimReader:mexError',msg));
    end
end