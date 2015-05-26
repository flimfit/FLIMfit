#pragma once
#include "ui_FitResultsWidget.h"
#include <QWidget>
#include <QTableView>
#include "ResultsTableModel.h"

#include "FitController.h"
#include <memory>

class FitResultsWidget : public QWidget, public Ui::FitResultsWidget
{
   Q_OBJECT

public:
   
   FitResultsWidget(QWidget* parent = 0) :
   QWidget(parent)
   {
      setupUi(this);
      
      results_table = new QTableView;
      mdi_area->addSubWindow(results_table);
   }

   void setFitController(std::shared_ptr<FitController> controller_)
   {
      controller = controller_;
      
      results_model = std::unique_ptr<ResultsTableModel>( new ResultsTableModel(controller->getResults()) );
      results_table->setModel(results_model.get());
   }
   
protected:
   std::shared_ptr<FitController> controller;
   QTableView* results_table;
   std::unique_ptr<ResultsTableModel> results_model;
};