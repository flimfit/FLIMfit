#pragma once

#include "ui_ProgressWidget.h"
#include <QWidget>
#include <QTimer>

#include "ProgressReporter.h"
#include <memory>

class ProgressWidget : public QWidget, public Ui::ProgressWidget
{
   Q_OBJECT

public:
   ProgressWidget(QWidget* parent = 0) :
   QWidget(parent)
   {
      setupUi(this);
      connect(terminate_button, &QPushButton::pressed, this, &ProgressWidget::terminate);
   
      timer = new QTimer(this);
      connect(timer, &QTimer::timeout, this, &ProgressWidget::update);
      timer->start(200);
   }
   
   void setProgressReporter(std::shared_ptr<ProgressReporter> reporter_)
   {
      reporter = reporter_;
   }
   
   void terminate()
   {
      if (reporter != nullptr)
         reporter->requestTermination();
   }
   
   void update()
   {
      if (reporter != nullptr)
      {
         if (reporter->isIndeterminate())
         {
            progress_bar->setMaximum(0);
         }
         else
         {
            float progress = reporter->getProgress();
            progress_bar->setMaximum(100);
            progress_bar->setValue(progress * 100);
         }
         
         if (reporter->isFinished())
         {
            timer->stop();
            close();
            deleteLater();
         }
      }
   }
   
protected:
   std::shared_ptr<ProgressReporter> reporter;
   QTimer* timer;
};