#include <QApplication>

// This file exists to link all mex files together so we can gather QT dependencies

int main(int argc, char *argv[])
{
   QApplication a(argc, argv);
   a.exec();
   return 0;
}