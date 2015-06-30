#pragma once

#include <QWidget>
#include <QFileDialog>
#include <QListWidgetItem>
#include <QSpinBox>

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
      
      connect(image_stacking_spin, static_cast<void (QSpinBox::*)(int)>(&QSpinBox::valueChanged), &importer, &FLIMImporter::setStackSize);
   
      QSettings settings;
      QVariant last_folder = settings.value("importer/last_folder");
      if (last_folder != QVariant())
         setFolder(last_folder.toString());
      
      image_stacking_spin->setValue(settings.value("importer/n_stack", 1).toInt());
      
      connect(select_all_button, &QPushButton::pressed, this, &ImporterWidget::selectAll);
      connect(select_none_button, &QPushButton::pressed, this, &ImporterWidget::selectNone);
   }
   
   void selectAll()
   {
      for(auto& item : file_items)
         item->setCheckState(Qt::Checked);
   }
   
   void selectNone()
   {
      for(auto& item : file_items)
         item->setCheckState(Qt::Unchecked);
   }
   
   void chooseFolder()
   {
      path = QFileDialog::getExistingDirectory(this, "Choose folder containing FLIM data");
      setFolder(path);
   }
   
   void setFolder(const QString& folder)
   {
      path = folder;
      folder_edit->setText(path);
      
      FileSet file_set = importer.getValidFilesFromFolder(path);
      
      file_items.clear();
      channel_items.clear();
      
      QListWidgetItem* item;
      while((item = files_list->takeItem(0)))
         delete item;
      while((item = channel_list->takeItem(0)))
         delete item;
      
      for(auto& f : file_set.files)
      {
         QString relative_path = f.canonicalPath();
         relative_path.replace(path, "", Qt::CaseInsensitive);
         relative_path.append(f.fileName());
         auto item = new QListWidgetItem(relative_path, files_list);
         item->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
         item->setCheckState(Qt::Checked);
         file_items.push_back(item);
      }
      
      for(int i=0; i<file_set.n_channels; i++)
      {
         auto item = new QListWidgetItem(QString("Channel %1").arg(i), channel_list);
         item->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
         item->setCheckState(Qt::Checked);
         channel_items.push_back(item);
      }
      
      QSettings settings;
      settings.setValue("importer/last_folder", path);
   }

   void openFiles()
   {
      try
      {
         QStringList selected_files;
         for(auto& item : file_items)
            if (item->checkState() == Qt::Checked)
               selected_files.push_back(item->text());
         
         vector<int> channels;
         for(int i=0; i<channel_items.size(); i++)
            if (channel_items[i]->checkState() == Qt::Checked)
               channels.push_back(i);
         
         auto images = importer.importFromFolder(path, selected_files, channels, project_path);

         emit newProgressReporter(importer.getProgressReporter());
         emit newImageSet(images);
         
         close();
         deleteLater();
      }
      catch(std::runtime_error e)
      {
         QMessageBox::critical(this, "Error loading data", e.what());
      }
      
      QSettings settings;
      settings.setValue("importer/n_stack", importer.getStackSize());
   }
   
signals:
   void newImageSet(std::shared_ptr<FLIMImageSet> images);
   void newProgressReporter(std::shared_ptr<ProgressReporter> reporter);
   
protected:
   FLIMImporter importer;
   QString path;
   QString project_path;
   QList<QListWidgetItem*> file_items;
   QList<QListWidgetItem*> channel_items;
};