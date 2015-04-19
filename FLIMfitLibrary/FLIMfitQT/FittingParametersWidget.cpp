#include "FittingParametersWidget.h"

#include <QApplication>

FittingParametersWidget::FittingParametersWidget(QWidget* parent) :
   QWidget(parent)
{
   setupUi(this);

   connect(add_group_button, &QPushButton::pressed, this, &FittingParametersWidget::AddGroup);
}

void FittingParametersWidget::SetDecayModel(std::shared_ptr<DecayModel> decay_model_)
{
   decay_model = decay_model_;
   list_model = new ParameterListModel(decay_model);
   delegate = new ParameterListDelegate(this);

   parameter_tree->setModel(list_model);
   parameter_tree->setItemDelegate(delegate);

   //parameter_tree->setItemsExpandable(false);
   parameter_tree->setAllColumnsShowFocus(false);
   parameter_tree->header()->setSectionsMovable(false);
   parameter_tree->header()->setSectionResizeMode(QHeaderView::ResizeToContents);
   parameter_tree->expandAll();
}

void FittingParametersWidget::AddGroup()
{
   int group_type = group_type_combo->currentIndex();

   if (group_type == MultiexponentialDecay)
   {

   }
}


int main(int argc, char *argv[])
{

   auto decay_model = std::make_shared<DecayModel>();

   decay_model->AddDecayGroup(std::make_shared<MultiExponentialDecayGroup>(3));
   decay_model->AddDecayGroup(std::make_shared<FretDecayGroup>(1, 2));

   QApplication app(argc, argv);
   app.setOrganizationName("FLIMfit");
   app.setApplicationName("FLIMfit");
   FittingParametersWidget mainWin;
   mainWin.SetDecayModel(decay_model);
   mainWin.show();
   return app.exec();
}