#pragma once
#include "ui_DecayWidget.h"
#include <QWidget>
#include <QVector>
#include <QAction>

#include "FLIMImage.h"

#include "cv.h"
#include <opencv/highgui.h>
#include <memory>

class DecayWidget : public QWidget, public Ui::DecayWidget
{
   Q_OBJECT

public:

   enum DisplayMode { DisplayLinear, DisplayLogarithmic };
   
   DecayWidget(QWidget* parent) :
      QWidget(parent)
   {
      setupUi(this);
      connect(this, &DecayWidget::recalculateLater, this, &DecayWidget::recalculate, Qt::QueuedConnection);
   
      decay_plot->xAxis->setLabel("Time (ps)");
      decay_plot->yAxis->setLabel("Intensity");
      
      connect(display_mode_combo, static_cast<void (QComboBox::*)(int)>(&QComboBox::currentIndexChanged), this, &DecayWidget::setDisplayMode);
      
      colors.push_back(Qt::darkBlue);
      colors.push_back(Qt::darkRed);
      colors.push_back(Qt::darkGreen);
      colors.push_back(Qt::magenta);
      
      QAction* save_action = new QAction("Save Decay...", this);
      connect(save_action, &QAction::triggered, this, &DecayWidget::saveDecay);
      
      addAction(save_action);
   }

   void setImage(std::shared_ptr<FLIMImage> image_)
   {
      image = image_;
      auto acq = image->getAcquisitionParameters();
      mask = cv::Mat(acq->n_x, acq->n_y, CV_8U, 1);
      emit recalculateLater();
   }
   
   void recalculate()
   {
      if (image == nullptr)
         return;
      
      image->getDecay(mask, decay);
      
      auto t = image->getAcquisitionParameters()->getTimePoints();
      auto x = QVector<double>::fromStdVector(t);
      auto xfit = QVector<double>::fromStdVector(t_fit);
      
      int n_decay = decay.size();
      for(int i=0; i<n_decay; i++)
      {
         if (decay_plot->graphCount() <= i)
            decay_plot->addGraph();

         auto graph = decay_plot->graph(i);
         graph->setPen(QPen(colors[i]));
         graph->setLineStyle(QCPGraph::lsNone);
         graph->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssCircle, 4));
         graph->setData(x, QVector<double>::fromStdVector(decay[i]));
         graph->rescaleAxes(i>0);
      }
      
      int n_fit = fit.size();
      for(int i=0; i<n_fit; i++)
      {
         int idx = i + n_decay;
         if (decay_plot->graphCount() <= idx)
            decay_plot->addGraph();
         
         auto graph = decay_plot->graph(idx);
         graph->setPen(QPen(colors[i]));
         graph->setData(xfit, QVector<double>::fromStdVector(fit[i]));
      }
      
      decay_plot->replot();
   }

   void setSelection(QRect selection)
   {
      cv::Point top_left(selection.topLeft().x(), selection.topLeft().y());
      cv::Point bottom_right(selection.bottomRight().x(), selection.bottomRight().y());
      cv::Rect sel(top_left, bottom_right);
      
      mask = cv::Scalar(0);
      cv::rectangle(mask, sel, 1, CV_FILLED);
      
      recalculate();
   }
   
   cv::Mat getSelectionMask()
   {
      return mask;
   }
   
   void setDisplayMode(int display_mode)
   {
      QCPAxis::ScaleType type;
      if (display_mode == DisplayLinear)
         type = QCPAxis::ScaleType::stLinear;
      else
         type = QCPAxis::ScaleType::stLogarithmic;
      
      decay_plot->yAxis->setScaleType(type);
      decay_plot->replot();
   }
   
   void setFit(const std::vector<double>& t_fit_, const std::vector<std::vector<double>>& fit_)
   {
      t_fit = t_fit_;
      fit = fit_;
      recalculate();
   }
   
   void saveDecay()
   {
      QString filename = QFileDialog::getSaveFileName(this, "Choose File Name", "", "CSV File (*.csv)");
      if (filename == "")
         return;
      
      QFile file(filename);
      file.open(QIODevice::WriteOnly);
      QTextStream ts(&file);
      
      
      ts << "t (ps)";
      for(int i=0; i<decay.size(); i++)
         ts << ", Channel " << i;
      ts << "\n";
      
      auto t = image->getAcquisitionParameters()->getTimePoints();
      for(int i=0; i<t.size(); i++)
      {
         ts << t[i];
         for(int j=0; j<decay.size(); j++)
            ts << ", " << decay[j][i];
         ts << "\n";
      }
   }
   
signals:
   void recalculateLater();
   
protected:
   std::vector<std::vector<double>> decay;
   std::vector<std::vector<double>> fit;
   std::vector<double> t_fit;
   cv::Mat mask;
   std::shared_ptr<FLIMImage> image;
   std::vector<QColor> colors;
};