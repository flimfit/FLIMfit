
project(FLIMfitQT)

cmake_policy(SET CMP0020 NEW)
cmake_policy(SET CMP0043 NEW)

find_package(Qt5Widgets REQUIRED)
find_package(Qt5PrintSupport REQUIRED)
find_package(Qt5OpenGL REQUIRED)
find_package(OpenCV REQUIRED)

find_package(BOOST REQUIRED COMPONENTS system serialization)

qt5_wrap_ui(UI_HEADERS FittingParametersWidget.ui
                       DecayWidget.ui
                       FLIMfitWindow.ui
                       FittingWidget.ui
		                 FLIMImageWidget.ui
                       FitResultsWidget.ui
                       ProgressWidget.ui
                       ImporterWidget.ui
                       FLIMfitLauncher.ui
		                 PhasorWidget.ui)

#qt5_add_resources(UI_RESOURCES PuppetMasterResources.qrc
#                                qdarkstyle/style.qrc)

set(CMAKE_AUTOMOC ON)

set(SOURCE
   ColormappedImageWidget.cpp
   FittingParametersWidget.cpp
   ParameterListModel.cpp
   ParameterListDelegate.cpp
   ChannelFactorListModel.cpp
   ChannelFactorListDelegate.cpp
   DecayWidget.cpp
   main.cpp
   qcustomplot.cpp
   FLIMImageSet.cpp
   FLIMfitWindow.cpp
   FittingWidget.cpp
   FLIMImporter.cpp
   AbstractItemDelegate.cpp
)

set(HEADERS
   FittingParametersWidget.h
   ParameterListModel.h
   ParameterListDelegate.h
   ChannelFactorListModel.h
   ChannelFactorListDelegate.h
   DecayWidget.h
   FLIMfitWindow.h
   FLIMImporter.h
   FLIMImageSet.h
   FittingWidget.h
   qcustomplot.h
   ColormappedImageWidget.h
   FLIMImageWidget.h
   FLIMSetListView.h
   FitResultsWidget.h
   ProgressWidget.h
   ResultsTableModel.h
   AbstractItemDelegate.h
   ImporterWidget.h
   FLIMfitLauncher.h
   PhasorWidget.h
   SafeApplication.h
)

include_directories(../FLIMDecayModel 
                    ../DataFitter 
                    ../FLIMfit
                    ../FLIMReader/Source/FLIMReader
                    ${LEVMAR_INCLUDE_DIRS} 
                    ${CMAKE_CURRENT_BINARY_DIR}
                    ${CMAKE_CURRENT_SOURCE_DIR}
                    ${OpenCV_INCLUDE_DIRS})

link_directories(${LAPACKBLAS_DIR} "C:/local/boost_1_59_0/lib64-msvc-14.0/") # lapack doesn't give us the right path

add_executable(FLIMfitQT ${SOURCE} 
                         ${HEADERS} 
                         ${UI_HEADERS} 
                         ${UI_RESOURCES}
                         $<TARGET_OBJECTS:FLIMReader>)

set_target_properties(FLIMfitQT PROPERTIES LINK_FLAGS "/NODEFAULTLIB:library" )

target_link_libraries(FLIMfitQT
                           FLIMDecayModel
                           DataFitter
                           FLIMfit
                           levmar
                           Qt5::Widgets 
                           Qt5::PrintSupport
                           Qt5::Gui
                           Qt5::OpenGL
                           ${LAPACKBLAS_LIB_NAMES}
                           ${F2C_LIB_NAME}
                           ${OpenCV_LIBS}
                           ${FLIMDecayModel_LIBRARIES})