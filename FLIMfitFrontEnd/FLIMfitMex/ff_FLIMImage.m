function [varargout] = ff_FLIMImage(varargin)
    [varargout{1:nargout}] = FLIMfitMex('FLIMImage',varargin{:});
end