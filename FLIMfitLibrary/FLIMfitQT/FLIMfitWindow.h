#include "ui_FLIMfitWindow.h"
#include <QMainWindow>
#include "ProgressWidget.h"

class FLIMfitWindow : public QMainWindow, public Ui::FLIMfitWindow
{
   Q_OBJECT
public:
   FLIMfitWindow(QWidget* parent = 0) :
      QMainWindow(parent)
   {
      setupUi(this);
      
      connect(fitting_widget, &FittingWidget::newFitController, this, &FLIMfitWindow::setFitController);
      
   }
   
   void setFitController(std::shared_ptr<FLIMGlobalFitController> controller)
   {
      results_widget->setFitController(controller);
      main_tab->setCurrentIndex(2);
      
      ProgressWidget* progress = new ProgressWidget();
      progress->setProgressReporter(controller->getProgressReporter());
      progress_layout->addWidget(progress);
   }

protected:
};