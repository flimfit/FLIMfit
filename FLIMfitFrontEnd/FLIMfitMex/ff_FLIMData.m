function [varargout] = ff_FLIMData(varargin)
    [varargout{1:nargout}] = FLIMfitMexInterface('FLIMData',varargin{:});
end