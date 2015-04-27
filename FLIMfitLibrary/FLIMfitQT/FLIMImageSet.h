#pragma once
#include "FLIMImage.h"
#include "FLIMData.h"

#include <QAbstractListModel>

class FLIMImageSet : public QAbstractListModel
{
   Q_OBJECT

public:

   int rowCount(const QModelIndex & parent = QModelIndex()) const
   {
      return (int) images.size();
   }

   QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const
   {
      if (role != Qt::DisplayRole)
         return QVariant();

      return QString::fromStdString(images[index.row()]->name());
   }

   void AddImage(std::shared_ptr<FLIMImage> image)
   {
      images.push_back(image);
      // TODO : check that acq parameters match
   }

   std::shared_ptr<FLIMImage> GetImage(int idx)
   {
      return images[idx];
   }

   std::shared_ptr<AcquisitionParameters> GetAcquisitionParameters()
   {
      if (!images.empty())
         return images[0]->acquisitionParameters();
      else
         return nullptr;
   }

   std::shared_ptr<FLIMData> GetFLIMData()
   {
      auto data = std::make_shared<FLIMData>();

      AcquisitionParameters* acq = GetAcquisitionParameters().get();

      data->SetAcquisitionParmeters(*acq);
      data->SetData(images);

      return data;
   }

signals:
   void ImagesUpdated();

protected:

   std::vector<std::shared_ptr<FLIMImage>> images;
};