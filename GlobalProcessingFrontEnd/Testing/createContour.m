function createContour(TwoParamDataSet)
% createContour(XYData)
% Generates a contour plot of a 2-column data set in which the 1st and 2nd
% column contains the X and Y variables, respectively.
% Output variables:
% 2D histogram: Rows contain the distribution of the X
% variable (1st column in input data) according to the specified X scale.
% Columns contain the distribution of the Y variable (2nd column in input
% data) according to the specified Y scale. 
% If the check box 'SigmaPlot' is checked,
% the 2D histogram is transposed so that it can be used for plotting in 
% SigmaPlot using the 'XY Many Z' option. 
TwoParamDataSet=fliplr(TwoParamDataSet);
scrsz = get(0,'ScreenSize');
figuresize=[530,700];
buttonsize=[50,30];
minX=min(TwoParamDataSet(:,2));
maxX=max(TwoParamDataSet(:,2));
minY=min(TwoParamDataSet(:,1));
maxY=max(TwoParamDataSet(:,1));
numBinX=uint32(1+3.2*log10(size(TwoParamDataSet,1)));
numBinY=numBinX;
mainFigureHandle=figure('WindowStyle','Normal','Name','Interactive 2D histogram','Toolbar','none','Menubar','none','Position',[scrsz(3)/2-figuresize(1)/2,scrsz(4)/2-figuresize(2)/2,figuresize(1),figuresize(2)]);
xScalePanelHandle=uipanel(mainFigureHandle,'Title','X scale','Position',[0.05,0.88,0.9,0.1],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(xScalePanelHandle,'Style','Text','HorizontalAlignment','Left','String','Min','Position',[10,30,50,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(xScalePanelHandle,'Style','Edit','String',num2str(minX),'Position',[10,10,100,20],'Callback',{@guidataedit_callback,1});
uicontrol(xScalePanelHandle,'Style','Text','HorizontalAlignment','Left','String','Max','Position',[0.9/3*530,30,50,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(xScalePanelHandle,'Style','Edit','String',num2str(maxX),'Position',[0.9/3*530,10,100,20],'Callback',{@guidataedit_callback,2});
uicontrol(xScalePanelHandle,'Style','Text','HorizontalAlignment','Left','String','Number of bins','Position',[2*0.9/3*530,30,100,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(xScalePanelHandle,'Style','Edit','String',num2str(numBinX),'Position',[2*0.9/3*530,10,100,20],'Callback',{@guidataedit_callback,3});

yScalePanelHandle=uipanel(mainFigureHandle,'Title','Y scale','Position',[0.05,0.76,0.9,0.1],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(yScalePanelHandle,'Style','Text','HorizontalAlignment','Left','String','Min','Position',[10,30,50,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(yScalePanelHandle,'Style','Edit','String',num2str(minY),'Position',[10,10,100,20],'Callback',{@guidataedit_callback,4});
uicontrol(yScalePanelHandle,'Style','Text','HorizontalAlignment','Left','String','Max','Position',[0.9/3*530,30,50,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(yScalePanelHandle,'Style','Edit','String',num2str(maxY),'Position',[0.9/3*530,10,100,20],'Callback',{@guidataedit_callback,5});
uicontrol(yScalePanelHandle,'Style','Text','HorizontalAlignment','Left','String','Number of bins','Position',[2*0.9/3*530,30,100,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(yScalePanelHandle,'Style','Edit','String',num2str(numBinY),'Position',[2*0.9/3*530,10,100,20],'Callback',{@guidataedit_callback,6});

contourPanelHandle=uipanel(mainFigureHandle,'Title','Contours','Position',[0.05,0.54,0.9,0.2],'BackgroundColor',get(mainFigureHandle,'Color'));
modeHandle=uibuttongroup(contourPanelHandle,'Title','Mode','Position',[0.02 0.05 0.5 0.9],'BackgroundColor',get(mainFigureHandle,'Color'),'SelectionChangeFcn',{@modebutton_callback});
uicontrol('Style','Radio','String','Auto','Position',[5 75 100 15],'BackgroundColor',get(mainFigureHandle,'Color'),'Parent',modeHandle,'Tag','auto');
uicontrol('Style','Radio','String','Set number of contours','Position',[5 45 150 15],'BackgroundColor',get(mainFigureHandle,'Color'),'Parent',modeHandle,'Tag','number');
uicontrol('Style','Radio','String','Manual','Position',[5 15 100 15],'BackgroundColor',get(mainFigureHandle,'Color'),'Parent',modeHandle,'Tag','manual');
numberConHandle=uipanel(contourPanelHandle,'Title','Set number of contours','Position',[0.55 0.05 0.4 0.9],'BackgroundColor',get(mainFigureHandle,'Color'),'Visible','off');
uicontrol(numberConHandle,'Style','Edit','String','10','Position',[figuresize(1)*0.9*0.4/2-50/2 figuresize(2)*0.2*0.9/2-20/2 50 20],'Callback',{@guidataedit_callback,14});
manualHandle=uipanel(contourPanelHandle,'Title','Manually set contours','Position',[0.55 0.05 0.4 0.9],'BackgroundColor',get(mainFigureHandle,'Color'),'Visible','off');
uicontrol(manualHandle,'Style','Edit','Max',2,'String','0.0001,0.0002,0.0005,0.001,0.002,0.005,0.01,0.02,0.05','Position',[figuresize(1)*0.9*0.4/2-150/2 figuresize(2)*0.2*0.9/2-70/2-10 150 70],'Callback',{@guidataedit_callback,15});

outputPanelHandle=uipanel(mainFigureHandle,'Title','Output','Position',[0.70,0.05,0.25,0.45],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(outputPanelHandle,'Style','Text','HorizontalAlignment','Left','String','2D histogram','Position',[10,270,100,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(outputPanelHandle,'Style','Edit','String','conplot','Position',[10,250,100,20],'Callback',{@guidataedit_callback,9});
uicontrol(outputPanelHandle,'Style','Text','HorizontalAlignment','Left','String','X scale','Position',[10,220,100,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(outputPanelHandle,'Style','Edit','String','xs','Position',[10,200,100,20],'Callback',{@guidataedit_callback,10});
uicontrol(outputPanelHandle,'Style','Text','HorizontalAlignment','Left','String','Y scale','Position',[10,170,100,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(outputPanelHandle,'Style','Edit','String','ys','Position',[10,150,100,20],'Callback',{@guidataedit_callback,11});
uicontrol(outputPanelHandle,'Style','Text','HorizontalAlignment','Left','String','Contour levels','Position',[10,120,100,20],'BackgroundColor',get(mainFigureHandle,'Color'));
uicontrol(outputPanelHandle,'Style','Edit','String','co','Position',[10,100,100,20],'Callback',{@guidataedit_callback,18});
uicontrol(outputPanelHandle,'Style','checkbox','value',1,'String','SigmaPlot','Position',[10 60 100 15],'Callback',{@guidataedit_callback,19});
uicontrol(outputPanelHandle,'Style','Pushbutton','String','Exit','Position',[figuresize(1)*0.25/2-buttonsize(1)/2 10 buttonsize],'Callback',{@exitbutton_callback,mainFigureHandle});

set(mainFigureHandle,'CloseRequestFcn',{@exitbutton_callback,mainFigureHandle});

axisHandle=axes('OuterPosition',[0.05 0.03 0.65 0.65*figuresize(1)/figuresize(2)],'Position',[0.15 0.08 0.53 0.53*figuresize(1)/figuresize(2)],'Parent',mainFigureHandle);
xlabel('x');ylabel('y');
yScale=linspace(minY,maxY,numBinY);
xScale=linspace(minX,maxX,numBinX);
contourPlot=hist2d(TwoParamDataSet,yScale,xScale);
contourPlot=contourPlot/sum(sum(contourPlot));
contour(axisHandle,xScale(1:end-1),yScale(1:end-1),contourPlot);
% guidata 
% 1 - minX, 2 - maxX, 3 - numBinX
% 4 - minY, 5 - maxY, 6 - numBinY
% 7 - XYData, 8 - axisHandle
% 9 - 2D hist variable name, 10 - X scale variable name, 11 - Y scale variable name
% 12 - contour plot, 13 - contour type (1 auto, 2 nr set, 3 manual)
% 14 - nr of contours, 15 - contours, 16 - numberConHandle
% 17 - manualHandle, 18 - contour levels variable, 19 - SigmaPlot style
contourData={minX,maxX,numBinX,minY,maxY,numBinY,TwoParamDataSet,axisHandle,'conplot','xs','ys',contourPlot,1,10,[0.0001,0.0002,0.0005,0.001,0.002,0.005,0.01,0.02,0.05],numberConHandle,manualHandle,'co',1};
guidata(mainFigureHandle,contourData);

function modebutton_callback(src,eventdata)
tempData=guidata(src);
switch(get(eventdata.NewValue,'Tag'))
    case 'auto'
        set(tempData{16},'Visible','off');
        set(tempData{17},'Visible','off');
        tempData{13}=1;
    case 'number'
        set(tempData{16},'Visible','on');
        set(tempData{17},'Visible','off');
        tempData{13}=2;
    case 'manual'
        set(tempData{16},'Visible','off');
        set(tempData{17},'Visible','on');
        tempData{13}=3;
end
tempData{12}=replot_contour(tempData{1},tempData{2},tempData{3},tempData{4},tempData{5},tempData{6},tempData{7},tempData{8},tempData{13},tempData{14},tempData{15});
guidata(src,tempData);

function newPlot=replot_contour(minx,maxx,binx,miny,maxy,biny,xydata,ah,contourtype,nrcontour,allcontours)
xScale=linspace(minx,maxx,binx);
yScale=linspace(miny,maxy,biny);
newPlot=hist2d(xydata,yScale,xScale);
newPlot=newPlot/sum(sum(newPlot));
switch(contourtype)
    case 1
        contour(ah,xScale(1:end-1),yScale(1:end-1),newPlot);
    case 2
        contour(ah,xScale(1:end-1),yScale(1:end-1),newPlot,nrcontour);
    case 3
        contour(ah,xScale(1:end-1),yScale(1:end-1),newPlot,allcontours);
end


function exitbutton_callback(src,eventdata,fh)
tempData=guidata(src);
xScale=linspace(tempData{1},tempData{2},tempData{3});
yScale=linspace(tempData{4},tempData{5},tempData{6});
if ~isempty(tempData{9})
    if tempData{19}
        assignin('base',tempData{9},tempData{12}');
    else
        assignin('base',tempData{9},tempData{12});
    end
end
if ~isempty(tempData{10})
    assignin('base',tempData{10},xScale');
end
if ~isempty(tempData{11})
    assignin('base',tempData{11},yScale');
end
if ~isempty(tempData{18})
    assignin('base',tempData{18},get(get(tempData{8},'Children'),'LevelList')');
end
delete(fh)

function guidataedit_callback(src,eventdata,whichOne)
% possible values of whichOne: 1,2,3,4,5,6,9,10,11,14,15,18,19
tempData=guidata(src);
switch(whichOne)
    case {1,2,3,4,5,6,14}
        newDataItem=str2double(get(src,'String'));
    case 15
        newDataItem=str2num(get(src,'String'));
    case 19
        newDataItem=get(src,'Value');
    otherwise % 9,10,11,18
        newDataItem=get(src,'String');
end
tempData{whichOne}=newDataItem;
if ismember(whichOne,[1 2 3 4 5 6 14 15])
    tempData{12}=replot_contour(tempData{1},tempData{2},tempData{3},tempData{4},tempData{5},tempData{6},tempData{7},tempData{8},tempData{13},tempData{14},tempData{15});
end
guidata(src,tempData);


function mHist = hist2d (mX, vYEdge, vXEdge)
[nRow, nCol] = size(mX);
if nCol < 2
    error ('mX has less than two columns')
end

nRow = length (vYEdge)-1;
nCol = length (vXEdge)-1;

vRow = mX(:,1);
vCol = mX(:,2);

mHist = zeros(nRow,nCol);

for iRow = 1:nRow
    rRowLB = vYEdge(iRow);
    rRowUB = vYEdge(iRow+1);
    
    [mIdxRow] = find (vRow > rRowLB & vRow <= rRowUB);
    vColFound = vCol(mIdxRow);
    
    if (~isempty(vColFound))
        
        
        vFound = histc (vColFound, vXEdge);
        
        nFound = (length(vFound)-1);
        
        if (nFound ~= nCol)
            [nFound nCol]
            error ('hist2d error: Size Error')
        end
        
        [nRowFound, nColFound] = size (vFound);
        
        nRowFound = nRowFound - 1;
        nColFound = nColFound - 1;
        
        if nRowFound == nCol
            mHist(iRow, :)= vFound(1:nFound)';
        elseif nColFound == nCol
            mHist(iRow, :)= vFound(1:nFound);
        else
            error ('hist2d error: Size Error')
        end
    end
    
end