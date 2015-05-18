#pragma once

#include <QWidget>
#include <QFileDialog>


#include "ui_ImporterWidget.h"
#include "FLIMImageSet.h"
#include "FLIMImporter.h"

class ImporterWidget : public QWidget, public Ui::ImporterWidget
{
   Q_OBJECT

public:
   
   ImporterWidget(const QString& project_path, QWidget* parent = 0) :
   QWidget(parent),
   project_path(project_path)
   {
      setupUi(this);
      
      connect(folder_choose_button, &QPushButton::clicked, this, &ImporterWidget::chooseFolder);
      connect(button_box, &QDialogButtonBox::rejected, this, &QWidget::close);
      connect(button_box, &QDialogButtonBox::rejected, this, &QWidget::deleteLater);
      connect(button_box, &QDialogButtonBox::accepted, this, &ImporterWidget::openFiles);
   }
   
   void chooseFolder()
   {
      path = QFileDialog::getExistingDirectory(this, "Choose folder containing FLIM data");
      folder_edit->setText(path);
   }

   void openFiles()
   {
      try
      {
         auto images = FLIMImporter::importFromFolder(path, project_path);
         emit newImageSet(images);
         close();
         deleteLater();
      }
      catch(std::runtime_error e)
      {
         QMessageBox::critical(this, "Error loading data", e.what());
      }
   }
   
signals:
   void newImageSet(std::shared_ptr<FLIMImageSet> images);
   
protected:
   QString path;
   QString project_path;
};