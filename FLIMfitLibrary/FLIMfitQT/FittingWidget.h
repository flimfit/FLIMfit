#pragma once
#include "ui_FittingWidget.h"

#include "FittingParametersWidget.h"
#include "FLIMImageSet.h"
#include "QFitController.h"
#include "FLIMImageWidget.h"
#include "ResultsTableModel.h"
#include "PhasorWidget.h"

#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/binary_iarchive.hpp>

#include <memory>
#include <fstream>

class FittingWidget : public QWidget, protected Ui::FittingWidget
{
   Q_OBJECT
   
public:
   FittingWidget(QWidget* parent = 0);
   
   void setImageSet(std::shared_ptr<FLIMImageSet> images_);
   void importIRF();
   
   void fitSelected();
   void fit();
   
   void setDefaultModel();
      
signals:
   void newFitController(std::shared_ptr<QFitController> fit_controller);
   
protected:
   
   void selectedFitComplete();
   void connectAll();
   
   std::shared_ptr<FLIMImageSet> images;
   std::shared_ptr<QFitController> fit_controller;
   std::shared_ptr<QFitController> selected_fit_controller;
   std::shared_ptr<QDecayModel> decay_model;
   std::shared_ptr<QDataTransformationSettings> transform;
   FLIMImageWidget* image_widget;
   PhasorWidget* phasor_widget;
   QTableView* results_table;
   std::unique_ptr<ResultsTableModel> results_model;
   
private:
   template<class Archive>
   void load(Archive & ar, const unsigned int version);
   
   template<class Archive>
   void save(Archive & ar, const unsigned int version) const;
   
   friend class boost::serialization::access;
   BOOST_SERIALIZATION_SPLIT_MEMBER()
};

template<class Archive>
void FittingWidget::load(Archive & ar, const unsigned int version)
{
   ar & decay_model;
   ar & transform;
   ar & images;

   connectAll();
}

template<class Archive>
void FittingWidget::save(Archive & ar, const unsigned int version) const
{
   ar & decay_model;
   ar & transform;
   ar & images;
}