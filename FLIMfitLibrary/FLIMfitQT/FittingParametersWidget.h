#pragma once

#include <QWidget>
#include "ui_FittingParametersWidget.h"
#include "ParameterListModel.h"
#include "ParameterListDelegate.h"

class FittingParametersWidget : public QWidget, protected Ui::FittingParametersWidget
{
public:
   FittingParametersWidget(QWidget* parent = 0);
   void SetDecayModel(std::shared_ptr<DecayModel> decay_model_);

protected:

   enum GroupTypes { MultiexponentialDecay, FretDecay, AnisotropyDecay };

   void AddGroup();

   ParameterListModel* list_model;
   ParameterListDelegate* delegate;
   shared_ptr<DecayModel> decay_model;
};