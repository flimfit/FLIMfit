#include "AbstractItemDelegate.h"


   QDoubleSpinBox* AbstractItemDelegate::createDoubleSpin(QWidget * parent) const
   {
      auto *editor = new QDoubleSpinBox(parent);
      editor->setFrame(false);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, const_cast<AbstractItemDelegate*>(this), editor);
      connect(editor, static_cast<void (QDoubleSpinBox::*)(double)>(&QDoubleSpinBox::valueChanged), fcn);
      return editor;
   }

   QSpinBox* AbstractItemDelegate::createSpin(QWidget * parent) const
   {
      auto *editor = new QSpinBox(parent);
      editor->setFrame(false);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, const_cast<AbstractItemDelegate*>(this), editor);
      connect(editor, static_cast<void (QSpinBox::*)(int)>(&QSpinBox::valueChanged), fcn);
      return editor;
   }

   QComboBox* AbstractItemDelegate::createCombo(QWidget * parent) const
   {
      auto *editor = new QComboBox(parent);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, const_cast<AbstractItemDelegate*>(this), editor);
      connect(editor, static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged), fcn);
      editor->setFrame(false);
      return editor;
   }

   QComboBox* AbstractItemDelegate::createBoolCombo(QWidget * parent) const
   {
      auto* editor = new QComboBox(parent);
      editor->setFrame(false);
      editor->addItem("false", false);
      editor->addItem("true", true);

      auto fcn = std::bind(&AbstractItemDelegate::commitData, const_cast<AbstractItemDelegate*>(this), editor);
      connect(editor, static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged), fcn);
      return editor;
   }

   QLineEdit* AbstractItemDelegate::createLineEdit(QWidget * parent) const
   {
      auto *editor = new QLineEdit(parent);
      editor->setFrame(false);
      auto fcn = std::bind(&AbstractItemDelegate::commitData, const_cast<AbstractItemDelegate*>(this), editor);
      connect(editor, &QLineEdit::textChanged, fcn);
      return editor;
   }
