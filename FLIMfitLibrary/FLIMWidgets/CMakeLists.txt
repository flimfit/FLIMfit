
project(FLIMWidgets)


find_package(Qt5Widgets REQUIRED)
find_package(Qt5PrintSupport REQUIRED)
find_package(BOOST REQUIRED COMPONENTS system serialization)

qt5_wrap_ui(UI_HEADERS FittingParametersWidget.ui)

set(CMAKE_AUTOMOC ON)

set(SOURCE
   FittingParametersWidget.cpp
   ParameterListModel.cpp
   ParameterListDelegate.cpp
   ChannelFactorListModel.cpp
   ChannelFactorListDelegate.cpp
   AbstractItemDelegate.cpp
)

set(HEADERS
   FittingParametersWidget.h
   ParameterListModel.h
   ParameterListDelegate.h
   ChannelFactorListModel.h
   ChannelFactorListDelegate.h
   AbstractItemDelegate.h

)

set(FLIMWidgets_INCLUDE_DIRS ${CMAKE_CURRENT_BINARY_DIR} PARENT_SCOPE)

include_directories(${FLIMWidgets_INCLUDE_DIRS}
                    ${CMAKE_CURRENT_BINARY_DIR} 
                    ../FLIMDecayModel
                    ${CMAKE_CURRENT_SOURCE_DIR})

add_library(FLIMWidgets ${SOURCE} 
                        ${HEADERS} 
                        ${UI_HEADERS} 
                        ${UI_RESOURCES})

target_link_libraries(FLIMWidgets
                      FLIMDecayModel
                      Qt5::Widgets 
                      Qt5::PrintSupport
                      Qt5::Gui)