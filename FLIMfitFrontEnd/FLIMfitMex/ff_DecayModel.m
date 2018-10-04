function [varargout] = ff_DecayModel(varargin)
    [varargout{1:nargout}] = FLIMfitMex('DecayModel',varargin{:});
end