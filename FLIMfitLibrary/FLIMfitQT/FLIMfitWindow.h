#pragma once

#include "ui_FLIMfitWindow.h"
#include <QMainWindow>
#include "ProgressReporter.h"

class FLIMfitWindow : public QMainWindow, public Ui::FLIMfitWindow
{
   Q_OBJECT
   
public:
   FLIMfitWindow(const QString& project_file = QString(), QWidget* parent = 0);
   
   void importData();
   void newWindow();
   void saveProject();
   void newProjectFromDialog();
   void openProjectFromDialog();
   void openProject(const QString& file);
   
   void setFitController(std::shared_ptr<FitController> controller);
   void addProgressReporter(std::shared_ptr<ProgressReporter> reporter);
   
   void closeEvent(QCloseEvent *event);

signals:
   void openedProject();
   
protected:
   
   bool project_changed = false;
   
   void loadTestData();

   std::shared_ptr<FLIMImageSet> images;
   QString project_root;
   QString project_file;
};