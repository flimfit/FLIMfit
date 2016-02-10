#pragma once

#include <QWidget>
#include <QSize>
#include <QImage>
#include <QPainter>
#include <QVector>
#include <QRgb>
#include <QMouseEvent>
#include <QTransform>
#include <QRubberBand>

#include <functional>
#include <vector>
#include <limits>
#include <cmath>
#include <iostream>
#include <cv.h>

enum Colormap { Gray, Jet };

class ColormappedImageWidget : public QWidget
{
   Q_OBJECT

public:
   ColormappedImageWidget(QWidget* parent = 0);
   
   void setColormap(Colormap map);
   void setLimits(double lim_min_, double lim_max_);
   void setLimitsFixed(bool limits_fixed_);
   void setImage(cv::Mat image_);
   void addPainterFunction(std::function<void(QPainter&, QSize size)> fcn);
   
signals:
   void selectionUpdated(QRect selection);
   
protected:
 
   void computeImage();
   void paintEvent(QPaintEvent *event) Q_DECL_OVERRIDE;
   void mousePressEvent(QMouseEvent* event);
   void mouseMoveEvent(QMouseEvent* event);
   void mouseReleaseEvent(QMouseEvent* event);
   
private:
   
   std::vector<std::function<void(QPainter&, QSize)>> painting_fcns;
   
   QRgb getColor(double v);
   
   cv::Mat image;
   QImage mapped_image;
   double lim_min = 0;
   double lim_max = 1;
   bool limits_fixed = false;
   QVector<QRgb> colormap;
   QTransform transform;
   
   QPoint origin;
   QRubberBand* rubber_band = nullptr;
};