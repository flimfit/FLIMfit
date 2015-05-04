#pragma once
#include "PicoquantTTRReader.h"
#include "FLIMImage.h"

#include <QString>
#include <QDir>
#include <vector>
#include <memory>

class FLIMImporter
{
public:

   static std::shared_ptr<InstrumentResponseFunction> importIRF(const QString& filename)
   {
      std::string fname = filename.toStdString();
      std::unique_ptr<FLIMReader> reader(FLIMReader::createReader(fname));

      vector<int> channels = { 0, 1 };

      int n_chan = channels.size();
      auto t = reader->timepoints(); 

      assert(t.size() > 1);

      double timebin_width = t[1] - t[0];

      vector<double> data = reader->readData<double>(channels);
     
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


      for (auto& f : files)
      {
         QString full_path = QString("%1/%2").arg(folder).arg(f);
         std::string fpath = full_path.toStdString();
         auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(fpath));
         reader->setTemporalResolution(5);

         vector<int> channels = { 0, 1 };

         auto acq = std::make_shared<AcquisitionParameters>(0, 125000);
         acq->n_chan = channels.size();
         acq->SetImageSize(reader->numX(), reader->numY());
         acq->SetT(reader->timepoints());

         auto image = std::make_shared<FLIMImage>(acq, typeid(float));
         image->setName(f.toStdString());

         reader->readData(image->getDataPointer<float>(), channels);
         image->releasePointer<float>();
         images->addImage(image);
      }
      return images;
   }
};