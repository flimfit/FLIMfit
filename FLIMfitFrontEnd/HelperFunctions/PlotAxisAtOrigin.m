function h=PlotAxisAtOrigin(ax,x,y);
%PlotAxisAtOrigin Plot 2D axes through the origin
%   This is a 2D version of Plot3AxisAtOrigin written by Michael Robbins
%   File exchange ID: 3245. 
%
%   Have hun! 
%
%   Example:
%   x = -2*pi:pi/10:2*pi;
%   y = sin(x);
%   PlotAxisAtOrigin(x,y)
%

% PLOT
if nargin == 3 
    h=plot(ax,x,y);
    hold on;
else
    display('   Not 2D Data set !')
end;

% GET TICKS
X=get(ax,'Xtick');
Y=get(ax,'Ytick');

% GET LABELS
XL=get(ax,'XtickLabel');
YL=get(ax,'YtickLabel');

YLcell = cell(1,size(YL,1));
for i=1:size(YL,1)
    YLcell{i} = strrep(YL(i,:),' ','');
end

% GET OFFSETS
Xoff=diff(get(ax,'XLim'))./40;
Yoff=diff(get(ax,'YLim'))./40;

% DRAW AXIS LINEs
plot(ax,get(ax,'XLim'),[0 0],'k');
plot(ax,[0 0],get(ax,'YLim'),'k');

% Plot new ticks  
for i=1:length(X)
    plot(ax,[X(i) X(i)],[0 Yoff],'-k');
end;
for i=1:length(Y)
   line([-Xoff, 0],[Y(i) Y(i)],'Parent',ax,'Color','k','Clipping','off');
end;

% ADD LABELS
text(X,zeros(size(X))-2.*Yoff,XL,'Parent',ax);
text(zeros(size(Y))-1.25*Xoff,Y,YLcell,'Parent',ax,'HorizontalAlignment','right');
%-3.*Xoff
box(ax,'off');
% axis square;
axis(ax,'off');

