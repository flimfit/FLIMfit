#pragma once
#include "ui_DecayWidget.h"
#include <QWidget>
#include "FLIMData.h"

#include <memory>

class DecayWidget : public QWidget, public Ui::DecayWidget
{
   Q_OBJECT

public:

   DecayWidget(QWidget* parent) :
      QWidget(parent)
   {
      setupUi(this);
   
      decay_plot->addGraph();
      decay_plot->xAxis->setLabel("Time (ps)");
      decay_plot->yAxis->setLabel("Intensity");
   }

   void update()
   {

   }

   Q_PROPERTY(std::shared_ptr<FLIMData> data MEMBER data_);
   Q_PROPERTY(int image_index MEMBER image_index_);

protected:

   std::shared_ptr<FLIMData> data_;
   int image_index_ = 0;
};