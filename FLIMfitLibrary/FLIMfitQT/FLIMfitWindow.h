#include "ui_FLIMfitWindow.h"
#include <QWidget>

#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "FittingParametersWidget.h"

class FLIMfitWindow : public QMainWindow, public Ui::FLIMfitWindow
{
   Q_OBJECT
public:
   FLIMfitWindow(QWidget* parent = 0) :
      QMainWindow(parent)
   {
      setupUi(this);

      parameters_widget = new FittingParametersWidget(this);


      auto acq = std::make_shared<AcquisitionParameters>(0, 12500.0, false, 4);
      auto decay_model = std::make_shared<QDecayModel>();

      decay_model->SetAcquisitionParameters(acq);
      decay_model->AddDecayGroup(std::make_shared<QMultiExponentialDecayGroup>());
      decay_model->AddDecayGroup(std::make_shared<QFretDecayGroup>());

      parameters_widget->SetDecayModel(decay_model);

      parameters_dock->setWidget(parameters_widget);
   }

protected:

   FittingParametersWidget* parameters_widget;
};