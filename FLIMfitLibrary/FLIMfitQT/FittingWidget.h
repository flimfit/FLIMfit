#pragma once
#include "ui_FittingWidget.h"

#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "FittingParametersWidget.h"
#include "FLIMImageSet.h"
#include "FLIMImporter.h"
#include "FLIMGlobalFitController.h"

#include "TextReader.h"

#include <memory>

class FittingWidget : public QWidget, protected Ui::FittingWidget
{
public:
   FittingWidget(QWidget* parent) :
      QWidget(parent)
   {
      setupUi(this);

      connect(fit_button, &QPushButton::pressed, this, &FittingWidget::Fit);


      QString irf_name = "C:/Users/sean/Documents/FLIMTestData/2015-05-15 Dual FRET IRF.csv";

      auto irf = FLIMImporter::importIRF(irf_name);
      

      QString folder("C:/Users/sean/Documents/FLIMTestData");
      images = FLIMImporter::importFromFolder(folder);

      auto acq = images->GetAcquisitionParameters();
      acq->SetIRF(irf);
      decay_model = std::make_shared<QDecayModel>();

      decay_model->SetAcquisitionParameters(acq);
      decay_model->AddDecayGroup(std::make_shared<QMultiExponentialDecayGroup>());
      decay_model->AddDecayGroup(std::make_shared<QFretDecayGroup>());

      data_list->setModel(images.get());

      parameters_widget->SetDecayModel(decay_model);

      Fit();
   }

   void Fit()
   {
      fit_controller = std::make_shared<FLIMGlobalFitController>();

      auto data = images->GetFLIMData();
      fit_controller->SetData(data);
      fit_controller->SetModel(decay_model);

      fit_controller->Init();
      fit_controller->RunWorkers();
   }

protected:
   std::shared_ptr<FLIMImageSet> images;
   std::shared_ptr<FLIMGlobalFitController> fit_controller;
   std::shared_ptr<QDecayModel> decay_model;
};