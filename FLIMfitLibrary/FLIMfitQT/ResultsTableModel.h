#pragma once

#include <QAbstractTableModel>
#include "FitResults.h"
#include <memory>

class ResultsTableModel : public QAbstractTableModel
{
   Q_OBJECT
   
public:
   ResultsTableModel(std::shared_ptr<FitResults> fit_results_)
   {
      fit_results = fit_results_;
   }
   
   QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const
   {
      if (role != Qt::DisplayRole)
         return QVariant();
      
      if (orientation == Qt::Vertical)
      {
         return QString::fromStdString(fit_results->GetOutputParamNames()[section]);
      }
      else
      {
         return section;
      }
   }

   QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const
   {
      if (role != Qt::DisplayRole)
         return QVariant();
      
      auto stats = fit_results->GetStats();
      return stats.GetStat(index.row(), index.column(), PARAM_MEAN);
   }
   
   int rowCount(const QModelIndex& parent = QModelIndex()) const
   {
      return fit_results->GetNumOutputParams();
   }
   
   int columnCount(const QModelIndex & parent = QModelIndex()) const
   {
      return fit_results->GetNumOutputRegions();
   }
   
protected:
   
   std::shared_ptr<FitResults> fit_results;
};