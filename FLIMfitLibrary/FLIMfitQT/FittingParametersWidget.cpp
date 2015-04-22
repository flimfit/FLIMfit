#include "FittingParametersWidget.h"

#include <QApplication>
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"

FittingParametersWidget::FittingParametersWidget(QWidget* parent) :
   QWidget(parent)
{
   setupUi(this);

   connect(add_group_button, &QPushButton::pressed, this, &FittingParametersWidget::AddGroup);
   connect(remove_group_button, &QPushButton::pressed, this, &FittingParametersWidget::RemoveGroup);
}

void FittingParametersWidget::SetDecayModel(std::shared_ptr<QDecayModel> decay_model_)
{
   decay_model = decay_model_;
 
   param_list_model = new ParameterListModel(decay_model, this);
   param_list_delegate = new ParameterListDelegate(this);

   parameter_tree->setModel(param_list_model);
   parameter_tree->setItemDelegate(param_list_delegate);

   parameter_tree->setItemsExpandable(false);
   parameter_tree->header()->setSectionsMovable(false);
   parameter_tree->header()->setSectionResizeMode(QHeaderView::ResizeToContents);
   parameter_tree->expandAll();


   channel_list_model = new ChannelFactorListModel(decay_model, this);
   channel_list_delegate = new ChannelFactorListDelegate(this);

   channel_factor_tree->setModel(channel_list_model);
   channel_factor_tree->setItemDelegate(channel_list_delegate);

   channel_factor_tree->setItemsExpandable(false);
   channel_factor_tree->header()->setSectionsMovable(false);
   channel_factor_tree->header()->setSectionResizeMode(QHeaderView::ResizeToContents);
   channel_factor_tree->expandAll();

   connect(decay_model.get(), &QDecayModel::GroupsUpdated, channel_factor_tree, &QTreeView::expandAll, Qt::QueuedConnection);

}

void FittingParametersWidget::AddGroup()
{
   param_list_model->addGroup(group_type_combo->currentIndex());
   parameter_tree->expandAll();
}

void FittingParametersWidget::RemoveGroup()
{
   param_list_model->removeGroup(parameter_tree->currentIndex());
}


int main(int argc, char *argv[])
{

   auto acq = std::make_shared<AcquisitionParameters>(0, 12500.0, false, 4);
   auto decay_model = std::make_shared<QDecayModel>();

   decay_model->SetAcquisitionParameters(acq);
   decay_model->AddDecayGroup(std::make_shared<QMultiExponentialDecayGroup>());
   decay_model->AddDecayGroup(std::make_shared<QFretDecayGroup>());

   QApplication app(argc, argv);
   app.setOrganizationName("FLIMfit");
   app.setApplicationName("FLIMfit");
   FittingParametersWidget mainWin;
   mainWin.SetDecayModel(decay_model);
   mainWin.show();
   return app.exec();
}