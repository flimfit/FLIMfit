#pragma once
#include <QListView>
#include <FLIMImageSet.h>

class FLIMSetListView : public QListView
{
   Q_OBJECT

public:

   FLIMSetListView(QWidget* parent) :
   QListView(parent)
   {
      
   }

protected:
   
   void selectionChanged(const QItemSelection& selected, const QItemSelection& deselected)
   {
      QListView::selectionChanged(selected, deselected);
      QModelIndexList indexes = selectedIndexes();
      
      if (!indexes.isEmpty())
      {
         FLIMImageSet* image_set = reinterpret_cast<FLIMImageSet*>(model());
         image_set->setCurrent(indexes[0]);
      }
   }
   
};