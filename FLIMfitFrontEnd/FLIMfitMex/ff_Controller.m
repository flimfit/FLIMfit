function [varargout] = ff_Controller(varargin)
    [varargout{1:nargout}] = FLIMfitMex('Controller',varargin{:});
end