#pragma once


#include <QStyledItemDelegate>

#include <QDoubleSpinBox>
#include <QSpinBox>
#include <QComboBox>
#include <QDoubleSpinBox>
#include <QLineEdit>
#include <functional>

class AbstractItemDelegate : public QStyledItemDelegate
{
   Q_OBJECT
   
public:
   AbstractItemDelegate(QObject * parent = 0) :
   QStyledItemDelegate(parent) {}
   
//   template <typename T>
   void commitDataW(QWidget* widget, double t)
   {
      commitData(widget);
   }

   QDoubleSpinBox* createDoubleSpin(QWidget * parent = 0) const;
   QSpinBox* createSpin(QWidget * parent = 0) const;
   QComboBox* createCombo(QWidget * parent = 0) const;
   QComboBox* createBoolCombo(QWidget * parent = 0) const;
   QLineEdit* createLineEdit(QWidget * parent = 0) const;
};
