function [varargout] = ff_FLIMData(varargin)
    [varargout{1:nargout}] = FLIMfitMex('FLIMData',varargin{:});
end