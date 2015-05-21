#pragma once

#include "ui_FLIMfitLauncher.h"
#include <QWidget>
#include <QSettings>
#include <QVariant>
#include <QFileInfo>
#include <QListWidgetItem>
#include "FLIMfitWindow.h"

class FLIMfitLauncher : public QWidget, protected Ui::FLIMfitLauncher
{
   Q_OBJECT

public:

   FLIMfitLauncher()
   {
      setupUi(this);
      connect(recent_projects_list, &QListWidget::itemDoubleClicked, this, &FLIMfitLauncher::listDoubleClicked);
      connect(choose_button, &QPushButton::clicked, this, &FLIMfitLauncher::openChosen);
      connect(open_button, &QPushButton::clicked, this, &FLIMfitLauncher::openProject);
      connect(new_button, &QPushButton::clicked, this, &FLIMfitLauncher::newProject);
   }
   
   void populateRecentList()
   {
      QSettings settings;
      QVariant v = settings.value("laucher/recent_projects");
      
      if (v == QVariant())
         return;
      
         QStringList recent_projects = v.toStringList();
         
      for(auto& p : recent_projects)
      {
         if (QFileInfo(p).exists())
         {
            auto item = new QListWidgetItem(p, recent_projects_list);
            item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
         }
      }
         
   }
   
   void listDoubleClicked(QListWidgetItem* item)
   {
      launch(item->text());
   }
   
   void newProject()
   {
      launch();
   }
   
   void openProject()
   {
      QSettings settings;
      QString last_project_location = settings.value("last_project_location", QString()).toString();
      QString file = QFileDialog::getOpenFileName(this, "Choose FLIMfit project", last_project_location, "FLIMfit Project (*.flimfit)");
      
      if (file.isEmpty())
         return;
      
      settings.setValue("last_project_location", file);
      launch(last_project_location);
   }
   
   void openChosen()
   {
      auto item = recent_projects_list->currentItem();
      if (item != nullptr)
         launch(item->text());
   }
   
   
   void launch(const QString& project = "")
   {
      auto window = new FLIMfitWindow(project);
      window->showMaximized();
      connect(window, &FLIMfitWindow::openedProject, this, &QWidget::close);
   }
   
};