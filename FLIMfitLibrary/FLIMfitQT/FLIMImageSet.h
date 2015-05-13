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

      return QString::fromStdString(images[index.row()]->getName());
   }

   void addImage(std::shared_ptr<FLIMImage> image)
   {
      if (current_image == nullptr)
      {
         current_image = image;
         emit currentImageChanged(image);
      }
      
      images.push_back(image);
      // TODO : check that acq parameters match
   }

   std::shared_ptr<FLIMImage> getImage(int idx)
   {
      return images[idx];
   }
   
   const std::vector<std::shared_ptr<FLIMImage>> getImages()
   {
      return images;
   }

   std::shared_ptr<AcquisitionParameters> getAcquisitionParameters()
   {
      if (!images.empty())
         return images[0]->getAcquisitionParameters();
      else
         return nullptr;
   }
   
   int getNumImages()
   {
      return images.size();
   }
   
   void setCurrent(const QModelIndex index)
   {
      current_image = images[index.row()];
      emit currentImageChanged(current_image);
   }
   
   shared_ptr<FLIMImage> getCurrentImage() { return current_image; }

signals:
   void imagesUpdated();
   void currentImageChanged(shared_ptr<FLIMImage> current_image);
protected:

   std::vector<std::shared_ptr<FLIMImage>> images;
   shared_ptr<FLIMImage> current_image;
};