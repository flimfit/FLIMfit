#pragma once

#include <QObject>
#include "FitController.h"

class QFitController : public QObject, public FitController
{
   Q_OBJECT
   
public:
   QFitController() :
   FitController() {};
   
   QFitController(const FitSettings& settings) :
   FitController(settings) {};
   
signals:
   void fitComplete();

protected:
   
   void setFitComplete()
   {
      FitController::setFitComplete();
      emit fitComplete();
   }
};