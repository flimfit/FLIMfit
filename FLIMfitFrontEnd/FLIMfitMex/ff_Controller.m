function [varargout] = ff_Controller(varargin)
    [varargout{1:nargout}] = FLIMfitMexInterface('Controller',varargin{:});
end