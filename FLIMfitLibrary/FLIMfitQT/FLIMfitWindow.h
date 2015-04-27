#include "ui_FLIMfitWindow.h"
#include <QMainWindow>


class FLIMfitWindow : public QMainWindow, public Ui::FLIMfitWindow
{
   Q_OBJECT
public:
   FLIMfitWindow(QWidget* parent = 0) :
      QMainWindow(parent)
   {
      setupUi(this);

   }

protected:
};