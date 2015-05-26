#include "FittingWidget.h"

#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "FLIMImporter.h"

#include <memory>
#include <fstream>


FittingWidget::FittingWidget(QWidget* parent) :
QWidget(parent)
{
   decay_model = std::make_shared<QDecayModel>();

   setupUi(this);
   parameters_widget->setAttribute(Qt::WA_MacShowFocusRect, false);
   data_list->setAttribute(Qt::WA_MacShowFocusRect, false);
   
   connect(fit_button, &QPushButton::pressed, this, &FittingWidget::fit);
   connect(fit_selected_button, &QPushButton::pressed, this, &FittingWidget::fitSelected);
   
   image_widget = new FLIMImageWidget(this);
   image_widget->setMinimumSize(500,500);
   mdi_area->addSubWindow(image_widget);
}

void FittingWidget::setImageSet(std::shared_ptr<FLIMImageSet> images_)
{
   images = images_;
   
   if (images_ == nullptr)
      return;
   
   setDefaultModel();
   connectAll();
}

void FittingWidget::connectAll()
{
   data_list->setModel(images.get());
   connect(images.get(), &FLIMImageSet::currentImageChanged, image_widget, &FLIMImageWidget::setImage);
   image_widget->setImage(images->getCurrentImage());
   parameters_widget->setDecayModel(decay_model);
}

void FittingWidget::setDefaultModel()
{
   transform = std::make_shared<QDataTransformationSettings>();

   auto dp = std::make_shared<TransformedDataParameters>(images->getAcquisitionParameters(), *transform.get());
   decay_model->SetTransformedDataParameters(dp);
   
   
   auto fret_group = std::make_shared<QFretDecayGroup>();
   fret_group->SetIncludeAcceptor(false);
   std::vector<double> ch_donor = { 0.12, 0.64, 0.11, 0.60 };
   fret_group->SetChannelFactors(0, ch_donor);
   
   decay_model->AddDecayGroup(fret_group);
}

void FittingWidget::importIRF()
{
   FLIMImporter importer;
   auto irf = importer.importIRFFromDialog();
   transform->irf = irf;
}

void FittingWidget::fitSelected()
{
   parameters_widget->finialise();
   
   try
   {
      
      fit_controller = std::make_shared<FitController>();
      fit_controller->setFitSettings(FitSettings(ALG_LM, MODE_IMAGEWISE));
      
      auto image = images->getCurrentImage();
      cv::Mat selection_mask = image_widget->getSelectionMask();
      auto sel = image->getRegionAsImage(selection_mask);
      
      auto data = std::make_shared<FLIMData>(sel, *transform.get());
      
      
      
      fit_controller->setData(data);
      fit_controller->setModel(decay_model);
      
      fit_controller->init();
      fit_controller->runWorkers();
      
      QThread::msleep(2000);
      
      int mask = 0;
      int n_valid = 0;
      vector<double> fit(2000);
      fit_controller->getFit(0, 1, &mask, fit.data(), n_valid);
      
      std::ofstream os("C:/Users/sean/Documents/FLIMTestData/results.csv");
      for (int i = 0; i < fit.size(); i++)
         os << fit[i] << "\n";
      
      emit newFitController(fit_controller);
   }
   catch(std::runtime_error e)
   {
      std::cout << "Error occurred: " << e.what() << "\n";
   }
   
   /*
    selected_fit_controller = std::make_shared<FitController>();
    selected_fit_controller->SetFitSettings(FitSettings(ALG_ML));
    
    
    auto image = images->getCurrentImage();
    cv::Mat selection_mask = image_widget->getSelectionMask();
    std::vector<std::vector<double>> decay;
    image->getDecay(selection_mask, decay);
    
    
    fit_controller->SetData(data);
    fit_controller->SetModel(decay_model);
    
    fit_controller->Init();
    fit_controller->RunWorkers();
    
    int mask = 0;
    int n_valid = 0;
    vector<double> fit(2000);
    fit_controller->GetFit(0, 1, &mask, fit.data(), n_valid);
    
    std::ofstream os("C:/Users/sean/Documents/FLIMTestData/results.csv");
    for (int i = 0; i < fit.size(); i++)
    os << fit[i] << "\n";
    */
   
}

void FittingWidget::fit()
{
   
   parameters_widget->finialise();
   
   try
   {
      
      fit_controller = std::make_shared<FitController>();
      fit_controller->setFitSettings(FitSettings(ALG_LM, MODE_IMAGEWISE));
      
      auto data = std::make_shared<FLIMData>(images->getImages(), *transform.get());
      
      fit_controller->setData(data);
      fit_controller->setModel(decay_model);
      
      fit_controller->init();
      fit_controller->runWorkers();
      
      emit newFitController(fit_controller);
      /*
       int mask = 0;
       int n_valid = 0;
       vector<double> fit(2000);
       fit_controller->GetFit(0, 1, &mask, fit.data(), n_valid);
       
       std::ofstream os("C:/Users/sean/Documents/FLIMTestData/results.csv");
       for (int i = 0; i < fit.size(); i++)
       os << fit[i] << "\n";
       */
   }
   catch(std::runtime_error e)
   {
      std::cout << "Error occurred: " << e.what() << "\n";
   }
   
}
