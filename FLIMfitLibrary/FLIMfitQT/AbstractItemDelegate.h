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
   
   QDoubleSpinBox* createDoubleSpin(QWidget * parent = 0) const
   {
      auto *editor = new QDoubleSpinBox(parent);
      editor->setFrame(false);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, this, editor);
      connect(editor, static_cast<void (QDoubleSpinBox::*)(double)>(&QDoubleSpinBox::valueChanged), this, fcn);
      return editor;
   }
   
   QSpinBox* createSpin(QWidget * parent = 0) const
   {
      auto *editor = new QSpinBox(parent);
      editor->setFrame(false);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, this, editor);
      connect(editor, static_cast<void (QSpinBox::*)(int)>(&QSpinBox::valueChanged), this, fcn);
      return editor;
   }
   
   QComboBox* createCombo(QWidget * parent = 0) const
   {
      auto *editor = new QComboBox(parent);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, this, editor);
      connect(editor, static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged), this, fcn);
      editor->setFrame(false);
      return editor;
   }
   
   QComboBox* createBoolCombo(QWidget * parent = 0) const
   {
      auto* editor = new QComboBox(parent);
      editor->setFrame(false);
      editor->addItem("false", false);
      editor->addItem("true", true);
      
      auto fcn = std::bind(&AbstractItemDelegate::commitData, this, editor);
      connect(editor, static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged), this, fcn);
      return editor;
   }
   
   QLineEdit* createLineEdit(QWidget * parent = 0) const
   {
      auto *editor = new QLineEdit(parent);
      editor->setFrame(false);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, this, editor);
      connect(editor, &QLineEdit::textChanged, this, fcn);
      return editor;
   }
};
