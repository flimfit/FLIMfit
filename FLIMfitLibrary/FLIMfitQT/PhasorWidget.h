#pragma once

#include <QObject>
#include <future>
#include "ui_PhasorWidget.h"
#include "PhasorCalculator.h"
class PhasorWidget : public QWidget, protected Ui::PhasorWidget
{
   Q_OBJECT
public:
   
   PhasorWidget(QWidget* parent) :
   QWidget(parent)
   {
      setupUi(this);
      
      auto semi_fcn = [](QPainter& painter, QSize image_size)
      {
         painter.setPen(QPen(Qt::red, 1));
         painter.drawArc(QRectF(QPointF(0,image_size.height()/2), image_size), 0, 180*16);
      };
      
      image_widget->addPainterFunction(semi_fcn);
      
      connect(channel_combo, static_cast<void(QComboBox::*)(int)>(&QComboBox::currentIndexChanged), this, &PhasorWidget::channelSelected);
      connect(display_combo, static_cast<void(QComboBox::*)(int)>(&QComboBox::currentIndexChanged), this, &PhasorWidget::displayModeSelected);
   }
   
   void displayModeSelected(int display_mode_)
   {
      display_mode = display_mode_;
      if (display_mode == 0)
         calc.setImageToDisplay(current_image);
      else
         calc.displayAllImages();
      update();
   }
   
   void setCurrentImage(std::shared_ptr<FLIMImage> image_)
   {
      current_image = image_;
      if (display_mode == 0)
      {
         calc.setImageToDisplay(current_image);
         update();
      }
   }
   
   void setImages(std::shared_ptr<FLIMImageSet> images_, std::shared_ptr<QDataTransformationSettings> transform_)
   {
      images = images_;
      transform = transform_;

      update_future = std::async(std::launch::async,
         [&]()
         {
            auto& im = images->getImages();
            
            calc.setImages(im, transform);
            update();
            
            int n_channels = 0;
            if (!im.empty())
               n_channels = images->getAcquisitionParameters()->n_chan;
            
            channel_combo->clear();
            for(int i=0; i<n_channels; i++)
               channel_combo->addItem(QString("Channel %1").arg(i));
            
         });
   }
   
   void channelSelected(int channel)
   {
      calc.setChannel(channel);
      update();
   }
   
protected:
   
   void update()
   {
      cv::Mat phasor_map = calc.getMap();
      image_widget->setImage(phasor_map);
   }
   
   PhasorCalculator calc;
   std::shared_ptr<FLIMImageSet> images;
   std::shared_ptr<FLIMImage> current_image;
   std::shared_ptr<QDataTransformationSettings> transform;
   std::future<void> update_future;
   int display_mode = 0;
};