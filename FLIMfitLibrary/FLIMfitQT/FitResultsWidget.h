#pragma once
#include "ui_FitResultsWidget.h"
#include <QWidget>

#include "FLIMGlobalFitController.h"
#include <memory>

class FitResultsWidget : public QWidget, public Ui::FitResultsWidget
{
   Q_OBJECT

public:
   
   FitResultsWidget(QWidget* parent = 0) :
   QWidget(parent)
   {
      setupUi(this);
   }
      void setFitController(std::shared_ptr<FLIMGlobalFitController> controller_)
   {
      controller = controller_;
   }
   
protected:
   std::shared_ptr<FLIMGlobalFitController> controller;
};