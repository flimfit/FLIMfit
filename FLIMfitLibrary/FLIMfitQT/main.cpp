#include <QApplication>
#include "FLIMfitWindow.h"

#include <memory>

int main(int argc, char *argv[])
{


   QApplication app(argc, argv);
   app.setOrganizationName("FLIMfit");
   app.setApplicationName("FLIMfit");

   FLIMfitWindow window;
   window.showMaximized();

   return app.exec();
}