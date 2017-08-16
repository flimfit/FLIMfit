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

   phasor_widget = new PhasorWidget(this);
   phasor_widget->setMinimumSize(500,500);
   mdi_area->addSubWindow(phasor_widget);

   results_table = new QTableView;
   mdi_area->addSubWindow(results_table);
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
   if (images != nullptr)
   {
      data_list->setModel(images.get());
      connect(images.get(), &FLIMImageSet::currentImageChanged, image_widget, &FLIMImageWidget::setImage);
      connect(images.get(), &FLIMImageSet::currentImageChanged, phasor_widget, &PhasorWidget::setCurrentImage);
      phasor_widget->setImages(images, transform);
      image_widget->setImage(images->getCurrentImage());
      parameters_widget->setDecayModel(decay_model);
   }   
}

void FittingWidget::setDefaultModel()
{
   transform = std::make_shared<QDataTransformationSettings>();

   auto dp = std::make_shared<TransformedDataParameters>(images->getAcquisitionParameters(), *transform.get());
   decay_model->setTransformedDataParameters(dp);
   
   
   auto fret_group = std::make_shared<FretDecayGroup>();
   fret_group->setIncludeAcceptor(false);
   std::vector<double> ch_donor = { 0.12, 0.64, 0.11, 0.60 };
   fret_group->setChannelFactors(0, ch_donor);
   
   decay_model->addDecayGroup(fret_group);
}

void FittingWidget::importIRF()
{
   try
   {
      FLIMImporter importer;
      auto irf = importer.importIRFFromDialog();
      transform->irf = irf;
   }
   catch (std::runtime_error e)
   {
      QMessageBox::critical(this, "Could not load IRF", e.what());
   }
}

void FittingWidget::fitSelected()
{
   parameters_widget->finialise();
   
   try
   {
      fit_controller = std::make_shared<QFitController>();
      fit_controller->setFitSettings(FitSettings(VariableProjection, Imagewise));
      connect(fit_controller.get(), &QFitController::fitComplete, this, &FittingWidget::selectedFitComplete);

      auto image = images->getCurrentImage();
      cv::Mat selection_mask = image_widget->getSelectionMask();
      auto sel = image->getRegionAsImage(selection_mask);
      
      auto data = std::make_shared<FLIMData>(sel, *transform.get());
      
      fit_controller->setData(data);
      fit_controller->setModel(decay_model);
      
      fit_controller->init();
      fit_controller->runWorkers();
      
      results_model = std::unique_ptr<ResultsTableModel>( new ResultsTableModel(fit_controller->getResults()) );
      connect(fit_controller.get(), &QFitController::fitComplete, results_model.get(), &ResultsTableModel::refresh);
      results_table->setModel(results_model.get());
      
//      emit newFitController(fit_controller);
   }
   catch(std::runtime_error e)
   {
      QMessageBox::critical(nullptr, "Exception occured", e.what());
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
    std::vector<double> fit(2000);
    fit_controller->GetFit(0, 1, &mask, fit.data(), n_valid);
    
    std::ofstream os("C:/Users/sean/Documents/FLIMTestData/results.csv");
    for (int i = 0; i < fit.size(); i++)
    os << fit[i] << "\n";
    */
   
}

void FittingWidget::selectedFitComplete()
{
   uint mask = 0;
   int n_valid = 0;
   auto dp = fit_controller->getData()->GetTransformedDataParameters();
   
   std::vector<double> raw_fit(dp->n_meas);
   fit_controller->getFit(0, 1, &mask, raw_fit.data(), n_valid);
   
   std::vector<std::vector<double>> fit(dp->n_chan, std::vector<double>(dp->n_t));
   for(int i=0; i<dp->n_chan; i++)
      for(int j=0; j<dp->n_t; j++)
         fit[i][j] = raw_fit[i*dp->n_t+j];
   
   auto t_fit = dp->getTimepoints();
   
   image_widget->setFit(t_fit, fit);
   
}

void FittingWidget::fit()
{
   
   parameters_widget->finialise();
   
   try
   {
      
      fit_controller = std::make_shared<QFitController>();
      fit_controller->setFitSettings(FitSettings(VariableProjection, Imagewise));
      
      auto data = std::make_shared<FLIMData>(images->getImages(), *transform.get());
      
      fit_controller->setData(data);
      fit_controller->setModel(decay_model);
      
      fit_controller->init();
      fit_controller->runWorkers();
      
      emit newFitController(fit_controller);
      /*
       int mask = 0;
       int n_valid = 0;
       std::vector<double> fit(2000);
       fit_controller->GetFit(0, 1, &mask, fit.data(), n_valid);
       
       std::ofstream os("C:/Users/sean/Documents/FLIMTestData/results.csv");
       for (int i = 0; i < fit.size(); i++)
       os << fit[i] << "\n";
       */
   }
   catch(std::runtime_error e)
   {
      QMessageBox::critical(nullptr, "Exception occured", e.what());
   }
   
}
