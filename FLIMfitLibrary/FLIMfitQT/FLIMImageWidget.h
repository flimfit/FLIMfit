#pragma once
#include "ui_FLIMImageWidget.h"
#include <QWidget>
#include "FLIMImage.h"

#include <memory>

class FLIMImageWidget : public QWidget, protected Ui::FLIMImageWidget
{
   Q_OBJECT
   
public:
   FLIMImageWidget(QWidget* parent = 0) :
   QWidget(parent)
   {
      setupUi(this);
      
      connect(image_widget, &ColormappedImageWidget::selectionUpdated, decay_widget, &DecayWidget::setSelection);
   }
   
   void setImage(std::shared_ptr<FLIMImage> image_)
   {
      image = image_;
      decay_widget->setImage(image);
      update();
   }
   
   cv::Mat getSelectionMask()
   {
      return decay_widget->getSelectionMask();
   }
   
protected:
   
   void update()
   {
      if (image == nullptr)
         return;
      
      cv::Mat intensity = image->getIntensity();
      image_widget->setImage(intensity);

   }
   
   std::shared_ptr<FLIMImage> image;
};