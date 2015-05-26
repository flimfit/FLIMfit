#include "FLIMImporter.h"

#include "PicoquantTTRReader.h"
#include "FLIMImage.h"
#include "ProgressReporter.h"

#include <QFileDialog>
#include <QString>
#include <QDir>
#include <vector>
#include <memory>
#include <cstdint>


FLIMImporter::FLIMImporter()
{
   filters << "*.ptu" << "*.pt3" << "*.csv";
}

std::shared_ptr<InstrumentResponseFunction> FLIMImporter::importIRFFromDialog()
{
   QString file = QFileDialog::getOpenFileName(nullptr, "Choose IRF", "IRF file (*.irf), CSV file (*.csv)");
   if (file == QString())
      return nullptr;
   else
      return importIRF(file);
}

std::shared_ptr<InstrumentResponseFunction> FLIMImporter::importIRF(const QString& filename)
{
   std::string fname = filename.toStdString();
   std::unique_ptr<FLIMReader> reader(FLIMReader::createReader(fname));
   
   int n_chan = reader->numChannels();
   auto t = reader->timepoints();
   
   assert(t.size() > 1);
   
   double timebin_width = t[1] - t[0];
   
   vector<double> data = reader->readData<double>();
   
   auto irf = std::make_shared<InstrumentResponseFunction>();
   irf->SetIRF(t.size(), n_chan, t[0], timebin_width, data.data());
   
   return irf;
}

std::shared_ptr<FLIMImageSet> FLIMImporter::importFromFolder(const QString& folder, const vector<int>& channels, const QString& project_folder)
{
   QFileInfoList matching_files = getValidFilesFromFolder(folder).files;
   QString first_ext = matching_files[0].completeSuffix();
   
   // Read as float for csv (might well be larger than MAX(uint16_t))
   // or read as uint16_t for image data (needs less memory)
   if (first_ext == "csv")
      return importFiles<float>(matching_files, channels, project_folder);
   else
      return importFiles<uint16_t>(matching_files, channels, project_folder);
}

std::shared_ptr<FLIMImageSet> FLIMImporter::importFromFolder(const QString& folder, const QStringList file_names, const vector<int>& channels, const QString& project_folder)
{
   QDir dir(folder);
   QFileInfoList files;
   for(auto& f : file_names)
      files.push_back(QFileInfo(folder, f));
   
   if (files.empty())
      throw std::runtime_error("No files found");
   
   QString first_ext = files[0].completeSuffix();
   
   // Read as float for csv (might well be larger than MAX(uint16_t))
   // or read as uint16_t for image data (needs less memory)
   if (first_ext == "csv")
      return importFiles<float>(files, channels, project_folder);
   else
      return importFiles<uint16_t>(files, channels, project_folder);
}

FileSet FLIMImporter::getValidFilesFromFolder(const QString& folder)
{
   QDir dir(folder);
   
   // move to reader...
   
   
   
   FileSet file_set;
   file_set.files = dir.entryInfoList(filters);
   
   if (file_set.files.empty())
      throw std::runtime_error("No files found");
   
   std::string file0 = file_set.files[0].absoluteFilePath().toStdString();
   auto reader = std::shared_ptr<FLIMReader>(FLIMReader::createReader(file0));
   file_set.n_channels = reader->numChannels();
   
   QString first_ext = file_set.files[0].completeSuffix();
   
   // Extract only files which match the first extension
   QFileInfoList matching_files;
   for(auto& f : file_set.files)
      if (f.completeSuffix() == first_ext)
         matching_files.push_back(f);
   
   return file_set;
}
