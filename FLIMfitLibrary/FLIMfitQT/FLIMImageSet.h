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

   std::shared_ptr<FLIMImage> getImage(int idx) const
   {
      return images[idx];
   }
   
   const std::vector<std::shared_ptr<FLIMImage>> getImages()
   {
      return images;
   }
   
   void setImages(const std::vector<std::shared_ptr<FLIMImage>>& images_)
   {
      images = images_;
      
      if (images.size() > 0)
         current_image = images[0];
      else
         current_image = nullptr;
      
      emit imagesUpdated();
      currentImageChanged(current_image);
   }

   std::shared_ptr<AcquisitionParameters> getAcquisitionParameters() const
   {
      if (!images.empty())
         return images[0]->getAcquisitionParameters();
      else
         return nullptr;
   }
   
   int getNumImages()
   {
      return (int) images.size();
   }
   
   void setCurrent(const QModelIndex index)
   {
      current_image = images[index.row()];
      emit currentImageChanged(current_image);
   }

   void setProjectRoot(const QString project_root)
   {
      for(auto& image : images)
      {
         image->setRoot(project_root.toStdString());
         image->init();
      }
   }
   
   std::shared_ptr<FLIMImage> getCurrentImage() { return current_image; }

signals:
   void imagesUpdated();
   void currentImageChanged(std::shared_ptr<FLIMImage> current_image);
protected:

   std::vector<std::shared_ptr<FLIMImage>> images;
   std::shared_ptr<FLIMImage> current_image;

private:
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
};

template<class Archive>
void FLIMImageSet::serialize(Archive & ar, const unsigned int version)
{
   ar & images;
   ar & current_image;
}
