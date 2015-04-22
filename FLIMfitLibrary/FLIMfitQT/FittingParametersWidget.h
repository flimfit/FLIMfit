#pragma once

#include <QWidget>
#include "ui_FittingParametersWidget.h"
#include "ParameterListModel.h"
#include "ParameterListDelegate.h"
#include "ChannelFactorListModel.h"
#include "ChannelFactorListDelegate.h"

class FittingParametersWidget : public QWidget, protected Ui::FittingParametersWidget
{
public:
   FittingParametersWidget(QWidget* parent = 0);
   void SetDecayModel(std::shared_ptr<QDecayModel> decay_model_);

protected:

   void AddGroup();
   void RemoveGroup();

   ParameterListModel* param_list_model;
   ParameterListDelegate* param_list_delegate;

   ChannelFactorListModel* channel_list_model;
   ChannelFactorListDelegate* channel_list_delegate;

   shared_ptr<QDecayModel> decay_model;
};