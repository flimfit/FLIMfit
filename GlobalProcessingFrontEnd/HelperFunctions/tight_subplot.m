function [ha hc] = tight_subplot(parent, N, Nh, Nw, print, sz, gap, marg_h, marg_w, units)

% tight_subplot creates "subplot" axes with adjustable gaps and margins
%
% ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
%
%   in:  Nh      number of axes in hight (vertical direction)
%        Nw      number of axes in width (horizontaldirection)
%        gap     gaps between the axes in normalized units (0...1)
%                   or [gap_h gap_w] for different gaps in height and width 
%        marg_h  margins in height in normalized units (0...1)
%                   or [lower upper] for different lower and upper margins 
%        marg_w  margins in width in normalized units (0...1)
%                   or [left right] for different left and right margins 
%
%  out:  ha     array of handles of the axes objects
%                   starting from upper left corner, going row-wise as in
%                   going row-wise as in
%
%  Example: ha = tight_subplot(3,2,[.01 .03],[.1 .01],[.01 .01])
%           for ii = 1:6; axes(ha(ii)); plot(randn(10,ii)); end
%           set(ha(1:4),'XTickLabel',''); set(ha,'YTickLabel','')

% Pekka Kumpulainen 20.6.2010   @tut.fi
% Tampere University of Technology / Automation Science and Engineering

if nargin<10
    units='pixels';
end

if nargin<7; gap = .01; end
if nargin<8 || isempty(marg_h); marg_h = .01; end
if nargin<9; marg_w = .01; end

if numel(gap)==1; 
    gap = [gap gap];
end
if numel(marg_w)==1; 
    marg_w = [marg_w marg_w];
end
if numel(marg_h)==1; 
    marg_h = [marg_h marg_h];
end

cbarw = 30;

children = get(parent,'Children');

ratio = sz(2)/sz(1);

for i=1:length(children)
    delete(children(i))
end

set(parent,'Units',units);

psize = get(parent,'Position');
% ratio = h/w

if print
    axh = sz(2);
    axw = sz(1);
    
    ph = (axh + gap(1)) * Nh - gap(1) + sum(marg_h);
    pw = (axw + gap(2) + cbarw) * Nw - gap(2) + sum(marg_w);
        
    psize = [psize(1:2) pw ph];
    set(parent,'Position',psize);
else
    
    axh = (psize(4)-sum(marg_h)-(Nh-1)*gap(1))/Nh; 
    axw = (psize(3)-sum(marg_w)-(Nw-1)*gap(2)-Nw*(cbarw+1))/Nw;

    ratio = sz(2)/sz(1);
    if axh > axw * ratio
        axh = axw * ratio;
    elseif axw > axh / ratio
        axw = axh / ratio;
    end
end

py = psize(4)-marg_h(2)-axh; 

ha = zeros(Nh*Nw,1);
hc = zeros(Nh*Nw,1);
ii = 0;
for ih = 1:Nh
    px = marg_w(1);
    
    for ix = 1:Nw
        ii = ii+1;
        if ii<=N
            ha(ii) = axes('Units',units, ...
                'Position',[px py axw axh], ...
                'XTickLabel','', ...
                'YTickLabel','','Parent',parent,'Box','on');
             hc(ii) = axes('Units',units, ...
                'Position',[px+axw py cbarw axh], ...
                'XTickLabel','', ...
                'YTickLabel','','Parent',parent,'Box','on');
        end
        px = px+axw+cbarw+gap(2);
    end
    py = py-axh-gap(1);
end

