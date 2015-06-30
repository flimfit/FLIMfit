#include <QApplication>
#include <QMessageBox>
#include <iostream>

class SafeApplication : public QApplication
{
public:
   SafeApplication(int &argc, char *argv[]) :
   QApplication(argc, argv)
   {
      
   }
   
   bool notify(QObject *receiver_, QEvent *event_)
   {
      try
      {
         return QApplication::notify(receiver_, event_);
      }
      catch (std::exception &ex)
      {
         QMessageBox::critical(nullptr, "Exception occured", ex.what());
      }
      return false;
   }
};