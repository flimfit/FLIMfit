#include "ChannelFactorListDelegate.h"
#include "ChannelFactorListModel.h"

#include <QDoubleSpinBox>
#include <QComboBox>

ChannelFactorListDelegate::ChannelFactorListDelegate(QObject *parent)
   : QStyledItemDelegate(parent)
{
}

QWidget *ChannelFactorListDelegate::createEditor(QWidget *parent,
   const QStyleOptionViewItem &option,
   const QModelIndex & index) const
{
   auto item = static_cast<ChannelFactorListItem*>(index.internalPointer());
   QWidget* widget;

   if (item->decayGroupIndex() >= 0)
   {
      auto *editor = new QDoubleSpinBox(parent);
      editor->setFrame(false);
      widget = editor;
   } 
   
   return widget;
}

void ChannelFactorListDelegate::setEditorData(QWidget *editor,
   const QModelIndex &index) const
{
   auto item = static_cast<ChannelFactorListItem*>(index.internalPointer());

   if (item->decayGroupIndex() >= 0 && index.column() > 0)
   {
      double value = index.model()->data(index, Qt::EditRole).toDouble();
      auto *spinBox = static_cast<QDoubleSpinBox*>(editor);
      spinBox->setRange(-1e10, 1e10);
      spinBox->setValue(value);
   }
}

void ChannelFactorListDelegate::setModelData(QWidget *editor, QAbstractItemModel *model,
   const QModelIndex &index) const
{
   auto item = static_cast<ChannelFactorListItem*>(index.internalPointer());
   QVariant value;

   if (item->decayGroupIndex() >= 0 && index.column() > 0)
   {
      auto *w = static_cast<QDoubleSpinBox*>(editor);
      w->interpretText();
      value = w->value();
   }

   if (!value.isNull())
      model->setData(index, value, Qt::EditRole);
}

void ChannelFactorListDelegate::updateEditorGeometry(QWidget *editor,
   const QStyleOptionViewItem &option, const QModelIndex &/* index */) const
{
   editor->setGeometry(option.rect);
}