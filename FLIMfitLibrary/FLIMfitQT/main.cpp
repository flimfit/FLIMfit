#include "SafeApplication.h"
#include "FLIMfitLauncher.h"

#include <memory>
int main(int argc, char *argv[])
{
   qRegisterMetaType<std::shared_ptr<FLIMImage>>("std::shared_ptr<FLIMImage>");

   SafeApplication app(argc, argv);
   app.setOrganizationName("FLIMfit");
   app.setOrganizationDomain("flimfit.org");
   app.setApplicationName("FLIMfit");

   auto launcher = new FLIMfitLauncher();
   launcher->show();
   
   //QString default_project = "/Users/sean/Documents/FLIMTestData/Test FLIMfit Project/project.flimfit";
   //FLIMfitWindow window(default_project);
   //window.showMaximized();

   return app.exec();
}