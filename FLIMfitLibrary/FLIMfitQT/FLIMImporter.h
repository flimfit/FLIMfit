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

   static std::shared_ptr<FLIMImageSet> importFromFolder(const QString& folder)
   {
      QDir dir(folder);

      // move to reader...
      QStringList filters;
      filters << "*.pt3" << "*.csv";

      QStringList files = dir.entryList(filters);

      if (files.empty())
         throw std::runtime_error("No files found");
      
      auto images = std::make_shared<FLIMImageSet>();


      int n_stack = 2;
      vector<int> channels = { 0, 1 };
      int channel_stride = n_stack * channels.size();
      
      vector<char> data_buf;
      
      std::vector<std::future<std::shared_ptr<FLIMImage>>> futures;
      for (int i=0; (i+n_stack)<=files.size(); i+=n_stack)
      {
         std::vector<std::string> stack_files;
         for (int j=0; j<n_stack; j++)
         {
            QString full_path = QString("%1/%2").arg(folder).arg(files[i+j]);
            stack_files.push_back(full_path.toStdString());
         }
         
         //futures.push_back(std::async([stack_files, channels, channel_stride](){
         
         auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(stack_files[0]));
         reader->setTemporalResolution(8);
         
         auto acq = std::make_shared<AcquisitionParameters>(0, 125000);
         acq->n_chan = channels.size() * n_stack;
         acq->SetImageSize(reader->numX(), reader->numY());
         acq->SetT(reader->timepoints());
         reader = nullptr;
         
         auto image = std::make_shared<FLIMImage>(acq, typeid(uint16_t));
         image->setName(stack_files[0]);

         size_t sz = image->getImageSizeInBytes();
         data_buf.resize(sz);
         
         uint16_t* data_ptr = reinterpret_cast<uint16_t*>(data_buf.data());
         
         // Read in rest of files in stack
         
         std::vector<std::future<void>> stack_futures;
         
         for (int j=0; j<n_stack; j++)
         {
            //stack_futures.push_back(std::async([&](int j){
               
               auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(stack_files[j]));
               reader->setTemporalResolution(8);

               uint16_t* next_ptr = data_ptr + j * channels.size() * acq->n_t_full;
               reader->readData(next_ptr, channels, channel_stride);
            //}, j));
         }
         
         for(auto& f : stack_futures)
            f.wait();

         uint16_t* img_ptr = image->getDataPointer<uint16_t>();
         memcpy(img_ptr, data_ptr, sz);
         image->releaseModifiedPointer<uint16_t>();
         images->addImage(image);
            //return image;
            
         //}));
      }
                                        
      //for(auto& f : futures)
      //   images->addImage(f.get());
      
      return images;
   }
};