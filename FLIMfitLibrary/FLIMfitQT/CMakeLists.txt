
project(FLIMfitQT)

cmake_policy(SET CMP0020 NEW)
cmake_policy(SET CMP0043 NEW)

find_package(Qt5Widgets REQUIRED)
find_package(Qt5Declarative REQUIRED)
find_package(Qt5PrintSupport REQUIRED)
find_package(Qt5OpenGL REQUIRED)


qt5_wrap_ui(UI_HEADERS FittingParametersWidget.ui
                       DecayWidget.ui
                       FLIMfitWindow.ui)

#qt5_add_resources(UI_RESOURCES PuppetMasterResources.qrc
#                                qdarkstyle/style.qrc)

set(CMAKE_AUTOMOC ON)

set(SOURCE
   FittingParametersWidget.cpp
   ParameterListModel.cpp
   ParameterListDelegate.cpp
   ChannelFactorListModel.cpp
   ChannelFactorListDelegate.cpp
   DecayWidget.cpp
   main.cpp
   qcustomplot.cpp
)

set(HEADERS
   FittingParametersWidget.h
   ParameterListModel.h
   ParameterListDelegate.h
   ChannelFactorListModel.h
   ChannelFactorListDelegate.h
   DecayWidget.h
   FLIMfitWindow.h
   qcustomplot.h
)

include_directories(../FLIMDecayModel ../DataFitter ../FLIMfit ${CMAKE_CURRENT_BINARY_DIR})

add_executable(FLIMfitQT ${SOURCE} 
                         ${HEADERS} 
                         ${UI_HEADERS} 
                         ${UI_RESOURCES}
                         $<TARGET_OBJECTS:FLIMreader>)

#set_target_properties(FLIMfitQT PROPERTIES LINK_FLAGS "/NODEFAULTLIB:library" )

target_link_libraries(FLIMfitQT
                           FLIMDecayModel
                           DataFitter
                           Qt5::Widgets 
                           Qt5::PrintSupport
                           Qt5::Gui
                           Qt5::OpenGL)
