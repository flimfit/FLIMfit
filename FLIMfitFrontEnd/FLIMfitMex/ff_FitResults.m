function [varargout] = ff_FitResults(varargin)
    [varargout{1:nargout}] = FLIMfitMex('FitResults',varargin{:});
end