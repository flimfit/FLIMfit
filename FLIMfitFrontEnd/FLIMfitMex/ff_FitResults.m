function [varargout] = ff_FitResults(varargin)
    [varargout{1:nargout}] = FLIMfitMexInterface('FitResults',varargin{:});
end