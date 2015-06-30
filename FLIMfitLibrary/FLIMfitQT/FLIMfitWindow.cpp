#include "FLIMfitWindow.h"

#include <QFileDialog>
#include <QDir>
#include <QFileInfo>
#include <QMessageBox>
#include <QDataStream>
#include "ProgressWidget.h"
#include "ImporterWidget.h"

#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/binary_iarchive.hpp>
#include <boost/serialization/export.hpp>
#include <boost/exception/all.hpp>

#include "AbstractDecayGroup.h"
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "AnisotropyDecayGroup.h"
#include "BackgroundLightDecayGroup.h"

BOOST_CLASS_EXPORT(AbstractDecayGroup);
BOOST_CLASS_EXPORT(QAbstractDecayGroup);
BOOST_CLASS_EXPORT(MultiExponentialDecayGroup);
BOOST_CLASS_EXPORT(QMultiExponentialDecayGroup);
BOOST_CLASS_EXPORT(FretDecayGroup);
BOOST_CLASS_EXPORT(QFretDecayGroup);
BOOST_CLASS_EXPORT(AnisotropyDecayGroup);
BOOST_CLASS_EXPORT(QAnisotropyDecayGroup);
BOOST_CLASS_EXPORT(BackgroundLightDecayGroup);
BOOST_CLASS_EXPORT(QBackgroundLightDecayGroup);


static qint32 flimfit_project_format_version = 1;
static std::string flimfit_project_magic_string = "FLIMfit Project File";


FLIMfitWindow::FLIMfitWindow(const QString& project_file, QWidget* parent) :
QMainWindow(parent)
{
   setupUi(this);
   
   connect(fitting_widget, &FittingWidget::newFitController, this, &FLIMfitWindow::setFitController);
   connect(new_project_action, &QAction::triggered, this, &FLIMfitWindow::newWindow);
   connect(open_project_action, &QAction::triggered, this, &FLIMfitWindow::openProjectFromDialog);
   connect(save_project_action, &QAction::triggered, this, &FLIMfitWindow::saveProject);
   connect(load_data_action, &QAction::triggered, this, &FLIMfitWindow::importData);
   connect(load_irf_action, &QAction::triggered, fitting_widget, &FittingWidget::importIRF);
   
   images = std::make_shared<FLIMImageSet>();
   
   if (project_file == QString())
      newProjectFromDialog();
   else
      openProject(project_file);
   
   //loadTestData();
   //fitting_widget->setImageSet(images);
}

void FLIMfitWindow::importData()
{
   ImporterWidget* importer = new ImporterWidget(project_root);
   connect(importer, &ImporterWidget::newProgressReporter, this, &FLIMfitWindow::addProgressReporter);
   connect(importer, &ImporterWidget::newImageSet, [&](std::shared_ptr<FLIMImageSet> new_images){
      images = new_images;
      fitting_widget->setImageSet(images);
      project_changed = true;
   });
   importer->show();
}

void FLIMfitWindow::newWindow()
{
   new FLIMfitWindow();
}


void FLIMfitWindow::newProjectFromDialog()
{
   QString file = QFileDialog::getSaveFileName(this, "Choose project location", QString(), "FLIMfit Project (*.flimfit)");
   
   if (file == QString()) // Pressed cancel
   {
      close();
      return;
   }
   
   QSettings settings;
   settings.setValue("last_project_location", file);

   
   QFileInfo info(file);
   QDir path(info.absolutePath());
   QString base_name = info.baseName();
   
   if (!path.mkdir(info.baseName()))
   {
      QMessageBox::critical(this, "Error", "Could not create project folder");
      return;
   }
   
   QString true_file = info.absolutePath();
   true_file.append("/").append(info.baseName()).append("/").append(info.fileName());
   
   std::string f = true_file.toStdString();
   
   openProject(true_file);
}


void FLIMfitWindow::openProjectFromDialog()
{
   QSettings settings;
   QString last_project_location = settings.value("last_project_location", QString()).toString();
   QString file = QFileDialog::getOpenFileName(this, "Choose FLIMfit project", last_project_location, "FLIMfit Project (*.flimfit)");
   
   if (!QFileInfo(project_file).exists() && !project_changed)
      openProject(file);
   else
   {
      FLIMfitWindow window(file);
   }
}

void FLIMfitWindow::saveProject()
{
   try
   {
      std::string file = project_file.toStdString();
      std::ofstream ofs(project_file.toStdString(), std::ifstream::binary);
      ofs << flimfit_project_magic_string << "\n";
      ofs << flimfit_project_format_version;
      boost::archive::binary_oarchive oa(ofs);
      // write class instance to archive
      oa << images;
      oa << *fitting_widget;
   }
   catch(std::exception& e)
   {
      QString msg = QString("Could not write project file: %1").arg(e.what());
      QMessageBox::critical(this, "Error", msg);
   }
}

void FLIMfitWindow::openProject(const QString& file)
{
   QFileInfo info(file);
   project_root = info.absolutePath();
   project_file = file;
   
   QSettings settings;
   QStringList recent_projects = settings.value("recent_projects", QStringList()).toStringList();
   if (!recent_projects.contains(project_file, Qt::CaseInsensitive))
   {
      recent_projects.append(project_file);
      settings.setValue("recent_projects", recent_projects);
   }
   
   if (info.exists())
   {
      try
      {
         std::ifstream ifs(project_file.toStdString(), std::ifstream::binary);
         
         char magicbuf[30];
         ifs.getline(magicbuf,30);
         if (flimfit_project_magic_string != magicbuf)
            throw std::runtime_error("Not a FLIMfit project file");
         
         quint32 version;
         ifs >> version;
         
         boost::archive::binary_iarchive ia(ifs);
         ia >> images;
         ia >> *fitting_widget;

         images->setProjectRoot(project_root);
         
      }
      catch(std::runtime_error e)
      {
         QString msg = QString("Could not read project file: %1").arg(e.what());
         QMessageBox::critical(this, "Error", msg);
         close();
         return;
      }
   }
   else
   {
      saveProject();
   }
   
   showMaximized();
   emit openedProject();
}

void FLIMfitWindow::setFitController(std::shared_ptr<QFitController> controller)
{
   results_widget->setFitController(controller);
   main_tab->setCurrentIndex(2);
   
   addProgressReporter(controller->getProgressReporter());
}

void FLIMfitWindow::addProgressReporter(std::shared_ptr<ProgressReporter> reporter)
{
   ProgressWidget* progress = new ProgressWidget();
   progress->setProgressReporter(reporter);
   progress_layout->addWidget(progress);
}

void FLIMfitWindow::loadTestData()
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
   
   FLIMImporter importer;
   auto irf = importer.importIRF(irf_name);
   images = importer.importFromFolder(folder, {0, 1}, project_root);
   
}

void FLIMfitWindow::closeEvent(QCloseEvent *event)
{
   if (project_changed)
   {
      auto dialog = QMessageBox::warning(this, "Save Project",
                                    "Save open project before closing?",
                                         QMessageBox::Cancel | QMessageBox::No | QMessageBox::Save);
      
      if(dialog == QMessageBox::Save)
      {
         saveProject();
         close();
      }
      else if (dialog == QMessageBox::Cancel)
         event->ignore();
      else
         close();
   }
}
