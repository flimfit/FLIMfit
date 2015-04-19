#include "ParameterListDelegate.h"
#include "ParameterListModel.h"

#include <QDoubleSpinBox>
#include <QComboBox>

ParameterListDelegate::ParameterListDelegate(QObject *parent)
   : QStyledItemDelegate(parent)
{
}

QWidget *ParameterListDelegate::createEditor(QWidget *parent,
   const QStyleOptionViewItem &option,
   const QModelIndex & index) const
{
   auto item = static_cast<ParameterListItem*>(index.internalPointer());
   QWidget* widget;

   if (item->type() == ParameterListItem::Parameter)
   {
      auto parameter = item->parameter();

      if (index.column() == 1)
      {
         auto *editor = new QDoubleSpinBox(parent);
         editor->setFrame(false);
         widget = editor;
      }
      else if (index.column() == 2)
      {
         auto *combo = new QComboBox(parent);
         combo->setFrame(false);

         auto fitting_types = parameter->allowed_fitting_types;
         for (auto& t : fitting_types)
            combo->addItem(FittingParameter::fitting_type_names[t], t);
         widget = combo;
      }
   }
   else if (item->type() == ParameterListItem::Option && index.column() == 1)
   {
      auto prop = item->property();
      if (prop.type() == QMetaType::Int)
      {
         auto* w = new QSpinBox(parent);
         w->setFrame(false);
         widget = w;
      }
      else if (prop.type() == QMetaType::Bool)
      {
         auto* w = new QComboBox(parent);
         w->setFrame(false);
         w->addItem("false", false);
         w->addItem("true", true);
         widget = w;
      } 
   }
   return widget;
}

void ParameterListDelegate::setEditorData(QWidget *editor,
   const QModelIndex &index) const
{
   auto item = static_cast<ParameterListItem*>(index.internalPointer());

   if (item->type() == ParameterListItem::Parameter)
   {
      if (index.column() == 1)
      {
         double value = index.model()->data(index, Qt::EditRole).toDouble();
         auto *spinBox = static_cast<QDoubleSpinBox*>(editor);
         spinBox->setRange(-1e10, 1e10);
         spinBox->setValue(value);
      }
      else if (index.column() == 2)
      {
         int value = index.model()->data(index, Qt::EditRole).toInt();
         auto* combo = static_cast<QComboBox*>(editor);
         int idx = combo->findData(value);
         if (idx != -1)
            combo->setCurrentIndex(idx);
      }
   }
   else if (item->type() == ParameterListItem::Option && index.column() == 1)
   {
      auto prop = item->property();
      if (prop.type() == QMetaType::Int)
      {
         int value = index.model()->data(index, Qt::EditRole).toInt();
         auto *w = static_cast<QSpinBox*>(editor);
         w->setValue(value);
      }
      else if (prop.type() == QMetaType::Bool)
      {
         int value = index.model()->data(index, Qt::EditRole).toBool();
         auto *w = static_cast<QComboBox*>(editor);
         int idx = w->findData(value);
         if (idx != -1)
            w->setCurrentIndex(idx);
      }
   }
}

void ParameterListDelegate::setModelData(QWidget *editor, QAbstractItemModel *model,
   const QModelIndex &index) const
{
   auto item = static_cast<ParameterListItem*>(index.internalPointer());
   QVariant value;

   if (item->type() == ParameterListItem::Parameter)
   {
      if (index.column() == 1)
      {
         auto *w = static_cast<QDoubleSpinBox*>(editor);
         w->interpretText();
         value = w->value();
      }
      else if (index.column() == 2)
      {
         auto* w = static_cast<QComboBox*>(editor);
         value = w->currentData();
      }
   }
   else if (item->type() == ParameterListItem::Option && index.column() == 1)
   {
      auto prop = item->property();
      if (prop.type() == QMetaType::Int)
      {
         auto *w = static_cast<QSpinBox*>(editor);
         w->interpretText();
         value = w->value();
      }
      else if (prop.type() == QMetaType::Bool)
      {
         auto *w = static_cast<QComboBox*>(editor);
         value = w->currentData();
      }
   }

   if (!value.isNull())
      model->setData(index, value, Qt::EditRole);
}

void ParameterListDelegate::updateEditorGeometry(QWidget *editor,
   const QStyleOptionViewItem &option, const QModelIndex &/* index */) const
{
   editor->setGeometry(option.rect);
}