function [varargout] = ff_FLIMImage(varargin)
    [varargout{1:nargout}] = FLIMfitMexInterface('FLIMImage',varargin{:});
end