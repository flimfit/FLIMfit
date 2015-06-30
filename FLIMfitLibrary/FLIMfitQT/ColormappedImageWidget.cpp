#include "ColormappedImageWidget.h"

ColormappedImageWidget::ColormappedImageWidget(QWidget* parent) :
QWidget(parent)
{
   setColormap(Gray);
   mapped_image = QImage(QSize(1, 1), QImage::Format_Indexed8);
   mapped_image.fill(0);
   mapped_image.setColorTable(colormap);
}
   
void ColormappedImageWidget::setLimits(double lim_min_, double lim_max_)
{
   lim_min = lim_min_;
   lim_max = lim_max_;
   
   computeImage();
}

void ColormappedImageWidget::setLimitsFixed(bool limits_fixed_)
{
   limits_fixed = limits_fixed_;
}

void ColormappedImageWidget::setImage(cv::Mat image_)
{
   image = image_;
   
   if (!limits_fixed)
      cv::minMaxIdx(image, &lim_min, &lim_max);
   
   computeImage();
}

void ColormappedImageWidget::computeImage()
{
   cv::Size sz = image.size();
   QSize image_size(sz.width, sz.height);
   
   if (mapped_image.size() != image_size)
      mapped_image = QImage(image_size, QImage::Format_Indexed8);
   
   int height = image_size.height();
   int width = image_size.width();
   double lim_scale = 256 / (lim_max - lim_min);
   
   for (int y=0; y<height; y++)
   {
      uchar* ptr = mapped_image.scanLine(y);
      for(int x = 0; x < width; x++)
      {
         float scaled = (image.at<float>(x,y) - lim_min) * lim_scale;
         scaled = (scaled < 0) ? 0 : scaled;
         scaled = (scaled > 255) ? 255 : scaled;
         uchar c = std::round(scaled);
         ptr[x] = c;
      }
   }
   
   mapped_image.setColorTable(colormap);
   
   update();
}

void ColormappedImageWidget::addPainterFunction(std::function<void(QPainter&, QSize)> fcn)
{
   painting_fcns.push_back(fcn);
}

void ColormappedImageWidget::paintEvent(QPaintEvent *event)
{
   QPainter painter(this);
   QSize widget_size = size();
   QSize image_size = mapped_image.size();
   
   // Determine image scaling
   double image_ratio = static_cast<double>(image_size.width()) / image_size.height();
   double widget_ratio = static_cast<double>(widget_size.width()) / widget_size.height();
   
   double scale;
   QPoint translation;
   if (widget_ratio < image_ratio)
   {
      scale = static_cast<double>(widget_size.width()) / image_size.width();
      translation = QPoint(0, (widget_size.height() - image_size.height() * scale) * 0.5);
   }
   else
   {
      scale = static_cast<double>(widget_size.height()) / image_size.height();
      translation = QPoint((widget_size.width() - image_size.width() * scale) * 0.5, 0);
   }
   
   painter.translate(translation);
   painter.scale(scale, scale);
   
   assert(!mapped_image.isNull());
   
   painter.drawImage(QPoint(0, 0), mapped_image);
   transform = painter.transform().inverted();
   
   for (auto& p : painting_fcns)
      p(painter, image_size);
}

void ColormappedImageWidget::mousePressEvent(QMouseEvent* event)
{
   origin = event->pos();
   if (!rubber_band)
      rubber_band = new QRubberBand(QRubberBand::Rectangle, this);
   
   rubber_band->setGeometry(QRect(origin, QSize()));
   rubber_band->show();
}

void ColormappedImageWidget::mouseMoveEvent(QMouseEvent* event)
{
   rubber_band->setGeometry(QRect(origin, event->pos()).normalized());
}

void ColormappedImageWidget::mouseReleaseEvent(QMouseEvent* event)
{
   rubber_band->hide();
   QPoint pos = event->pos();
   QRect selection(transform.map(origin), transform.map(pos));
   
   emit selectionUpdated(selection);
}

void ColormappedImageWidget::setColormap(Colormap map)
{
   if (map == Jet)
   {
      for(int i=0; i<256; i++)
         colormap.push_back(getColor(static_cast<double>(i) / 255));
   }
   else
   {
      for(int i=0; i<256; i++)
         colormap.push_back(qRgb(i,i,i));
      
   }
}

QRgb ColormappedImageWidget::getColor(double v)
{
   double c[] = {1.0,1.0,1.0}; // white
   
   if (v < 0.25) {
      c[0] = 0;
      c[1] = 4 * v;
   } else if (v < 0.5) {
      c[0] = 0;
      c[2] = 1 + 4 * (0.25 - v);
   } else if (v < 0.75) {
      c[0] = 4 * (v - 0.5);
      c[2] = 0;
   } else {
      c[1] = 1 + 4 * (0.75 - v);
      c[2] = 0;
   }
   
   return qRgb(255*c[0], 255*c[1], 255*c[2]);
}
