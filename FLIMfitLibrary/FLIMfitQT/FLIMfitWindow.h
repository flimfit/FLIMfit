#include "ui_FLIMfitWindow.h"
#include <QMainWindow>
#include <QFileDialog>
#include <QDir>
#include <QFileInfo>
#include <QMessageBox>
#include <QDataStream>
#include "ProgressWidget.h"

#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/binary_iarchive.hpp>

#include <fstream>

static qint32 flimfit_project_format_version = 1;

class FLIMfitWindow : public QMainWindow, public Ui::FLIMfitWindow
{
   Q_OBJECT
public:
   FLIMfitWindow(QWidget* parent = 0) :
      QMainWindow(parent)
   {
      setupUi(this);
      
      connect(fitting_widget, &FittingWidget::newFitController, this, &FLIMfitWindow::setFitController);
      connect(new_project_action, &QAction::triggered, this, &FLIMfitWindow::newProjectFromDialog);
      connect(open_project_action, &QAction::triggered, this, &FLIMfitWindow::openProjectFromDialog);
      connect(save_project_action, &QAction::triggered, this, &FLIMfitWindow::saveProject);
      
      openProject("/Users/sean/Documents/FLIMTestData/Test FLIMfit Project/project.flimfit");
      
      //loadTestData();
      fitting_widget->setImageSet(images);
   }
   
   
   void saveProject()
   {
      try
      {
         std::ofstream ofs(project_file.toStdString(), std::ifstream::binary);
         boost::archive::binary_oarchive oa(ofs);
         // write class instance to archive
         oa << images->getImages();
      }
      catch(std::exception e)
      {
         QString msg = QString("Could not write project file: %1").arg(e.what());
         QMessageBox::critical(this, "Error", msg);
      }
   }
   
   void newProjectFromDialog()
   {
      QString folder = QFileDialog::getExistingDirectory();
      newProject(folder);
   }

   
   void newProject(const QString& folder)
   {
      QString file = QFileDialog::getSaveFileName(this, "Choose project location", QString(), "FLIMfit Project (*.flimfit)");
      QFileInfo info(file);
      QDir path(info.absolutePath());
      QString base_name = info.baseName();
      if (!path.mkdir(info.baseName()))
      {
         QMessageBox::critical(this, "Error", "Could not create project folder");
         return;
      }
      
      path.setPath(info.baseName());
      project_file = path.filePath(info.fileName());
   }
   
   void openProjectFromDialog()
   {
      QString file = QFileDialog::getOpenFileName(this, "Choose FLIMfit project", QString(), "FLIMfit Project (*.flimfit)");
      openProject(file);
   }
   
   void openProject(const QString& file)
   {
      QFileInfo info(file);
      project_root = info.absolutePath();
      project_file = file;
      
      if (info.exists())
      {
         try
         {
            std::ifstream ifs(project_file.toStdString(), std::ifstream::binary);
            boost::archive::binary_iarchive ia(ifs);
            std::vector<std::shared_ptr<FLIMImage>> new_images;
            ia >> new_images;
            
            for(auto& image : new_images)
            {
               image->setRoot(project_root.toStdString());
               image->init();
            }
            
            images = std::make_shared<FLIMImageSet>();
            images->setImages(new_images);
            fitting_widget->setImageSet(images);
            
         }
         catch(std::exception e)
         {
            QString msg = QString("Could not read project file: %1").arg(e.what());
            QMessageBox::critical(this, "Error", msg);
         }
      }
   }
   
   void setFitController(std::shared_ptr<FLIMGlobalFitController> controller)
   {
      results_widget->setFitController(controller);
      main_tab->setCurrentIndex(2);
      
      ProgressWidget* progress = new ProgressWidget();
      progress->setProgressReporter(controller->getProgressReporter());
      progress_layout->addWidget(progress);
   }

protected:
   
   
   
   void loadTestData()
   {
      QString root = "/Users/sean/Documents/FLIMTestData";
      
      bool use_acceptor_test_data = true;
      
      QString folder, irf_name;
      if (!use_acceptor_test_data)
      {
         folder = QString("%1%2").arg(root).arg("/dual_data");
         irf_name = QString("%1%2").arg(root).arg("/2015-05-15 Dual FRET IRF.csv");
      }
      else
      {
         folder = QString("%1%2").arg(root).arg("/acceptor");
         irf_name = QString("%1%2").arg(root).arg("/acceptor-fret-irf.csv");
      }
      
      auto irf = FLIMImporter::importIRF(irf_name);
      images = FLIMImporter::importFromFolder(folder, project_root);
      
      auto acq = images->getAcquisitionParameters();
      acq->SetIRF(irf);
   }


   std::shared_ptr<FLIMImageSet> images;
   QString project_root;
   QString project_file;
};