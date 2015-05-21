#pragma once
#include "PicoquantTTRReader.h"
#include "FLIMImage.h"

#include <QString>
#include <QDir>
#include <vector>
#include <memory>
#include <cstdint>

class FLIMImporter
{
public:

   static std::shared_ptr<InstrumentResponseFunction> importIRF(const QString& filename)
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

   static std::shared_ptr<FLIMImageSet> importFromFolder(const QString& folder, const QString& project_folder = 0)
   {
      QDir dir(folder);

      // move to reader...
      QStringList filters;
      filters << "*.ptu" << "*.pt3" << "*.csv";

      QFileInfoList files = dir.entryInfoList(filters);

      if (files.empty())
         throw std::runtime_error("No files found");
      
      QString first_ext = files[0].completeSuffix();
      
      // Extract only files which match the first extension
      QStringList matching_files;
      for(int i=0; i<files.size(); i++)
         if (files[i].completeSuffix() == first_ext)
            matching_files.push_back(files[i].canonicalFilePath());
      
      // Read as float for csv (might well be larger than MAX(uint16_t))
      // or read as uint16_t for image data (needs less memory)
      if (first_ext == "csv")
         return importFiles<float>(matching_files, project_folder);
      else
         return importFiles<uint16_t>(matching_files, project_folder);
   }
   
   template <typename T>
   static std::shared_ptr<FLIMImageSet> importFiles(QStringList files, const QString& root)
   {
      auto images = std::make_shared<FLIMImageSet>();
      
      int n_stack = 1;
      vector<int> channels = { 0, 1 };
      
      std::vector<std::future<std::shared_ptr<FLIMImage>>> futures;
      for (int i=0; (i+n_stack)<=files.size(); i+=n_stack)
      {
         QStringList stack_files;
         for (int j=0; j<n_stack; j++)
            stack_files.push_back(files[i+j]);
         
         auto image = importStackedFiles<T>(stack_files, root, channels);
         images->addImage(image);
      }
      
      return images;
   }
   
   template <typename T>
   static std::shared_ptr<FLIMImage> importStackedFiles(QStringList stack_files, const QString& root, std::vector<int>& channels)
   {
      auto reader = std::shared_ptr<FLIMReader>(FLIMReader::createReader(stack_files[0].toStdString()));
      reader->setTemporalResolution(8);
      
      auto acq = std::make_shared<AcquisitionParameters>(0, 125000);
      acq->n_chan = channels.size() * stack_files.size();
      acq->SetImageSize(reader->numX(), reader->numY());
      acq->SetT(reader->timepoints());
      reader = nullptr;
      
      QFileInfo info(stack_files[0]);
      std::string basename = info.baseName().toStdString();
      
      auto image = std::make_shared<FLIMImage>(acq, typeid(T), basename, FLIMImage::DataMode::MappedFile, root.toStdString());
      
      auto read_fcn = [image, reader, stack_files, channels]()
      {
         if (image->hasData())
            return;
         
         auto acq = image->getAcquisitionParameters();
         int n_stack = stack_files.size();
         int channel_stride = n_stack * channels.size();
         
         size_t sz = image->getImageSizeInBytes();
         vector<char> data_buf(sz);
         T* data_ptr = reinterpret_cast<T*>(data_buf.data());

         for (int j=0; j<n_stack; j++)
         {
            auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(stack_files[j].toStdString()));
            reader->setTemporalResolution(8);
            
            T* next_ptr = data_ptr + j * channels.size() * acq->n_t_full;
            reader->readData(next_ptr, channels, channel_stride);
         }
         
         T* img_ptr = image->getDataPointer<T>();
         memcpy(img_ptr, data_ptr, sz);
         image->releaseModifiedPointer<T>();
      };
      
      image->setReadFuture(std::async(std::launch::async, read_fcn).share());
      
      return image;
   }
};