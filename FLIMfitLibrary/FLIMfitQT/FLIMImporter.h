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
      auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(filename.toStdString()));

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

      auto images = std::make_shared<FLIMImageSet>();

      if (!files.empty())
      {
         for (auto& f : files)
         {
            QString full_path = QString("%1/%2").arg(folder).arg(f);
            auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(full_path.toStdString()));
            reader->setTemporalResolution(5);

            vector<int> channels = { 0, 1 };

            auto acq = std::make_shared<AcquisitionParameters>(0, 125000);
            acq->n_chan = channels.size();
            acq->SetImageSize(reader->numX(), reader->numY());
            acq->SetT(reader->timepoints());

            auto image = std::make_shared<FLIMImage>(acq, typeid(float));
            image->setName(f.toStdString());

            reader->readData(image->dataPointer<float>(), channels);
            images->AddImage(image);
         }

      }
      return images;
   }
};