function [varargout] = ff_DecayModel(varargin)
    [varargout{1:nargout}] = FLIMfitMexInterface('DecayModel',varargin{:});
end