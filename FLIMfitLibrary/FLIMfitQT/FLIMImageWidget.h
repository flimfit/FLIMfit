#pragma once
#include "ui_FLIMImageWidget.h"
#include <QWidget>
#include "FLIMImage.h"

#include <memory>
#include <future>

class FLIMImageWidget : public QWidget, protected Ui::FLIMImageWidget
{
   Q_OBJECT
   
public:
   FLIMImageWidget(QWidget* parent = 0) :
   QWidget(parent)
   {
      update_complete = true;
      setupUi(this);
      
      connect(image_widget, &ColormappedImageWidget::selectionUpdated, decay_widget, &DecayWidget::setSelection);
      connect(this, &FLIMImageWidget::setImageLater, this, &FLIMImageWidget::setImage, Qt::QueuedConnection);
   }
   
   void setImage(std::shared_ptr<FLIMImage> image_)
   {
      if (!update_complete)
      {
         // We're still trying to set the last one...
         next_image = image_;
      }
      else
      {
         update_future = std::async(std::launch::async, std::bind(&FLIMImageWidget::update, this, image_));
      }
   }
   
   cv::Mat getSelectionMask()
   {
      return decay_widget->getSelectionMask();
   }
   
signals:
   void setImageLater(std::shared_ptr<FLIMImage> image_);

   
protected:
   
   void update(std::shared_ptr<FLIMImage> image_)
   {
      update_complete = false;
      image = image_;
      if (image == nullptr)
         return;

      cv::Mat intensity = image->getIntensity();
      image_widget->setImage(intensity);

      decay_widget->setImage(image);
      
      if (image != next_image)
         emit setImageLater(next_image);
      update_complete = true;
   }
   
   std::shared_ptr<FLIMImage> image;
   std::shared_ptr<FLIMImage> next_image;
   std::future<void> update_future;
   std::atomic<bool> update_complete;
};