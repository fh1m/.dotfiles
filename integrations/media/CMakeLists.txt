cmake_minimum_required(VERSION 3.22)
project(SenseiMedia LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Quick Qml)
find_package(MpvQt REQUIRED)
qt_add_qml_module(senseimedia URI Sensei.Media VERSION 1.0 SOURCES mpvsurface.h mpvsurface.cpp OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Sensei/Media")
target_link_libraries(senseimedia PRIVATE Qt6::Quick Qt6::Qml MpvQt::MpvQt)
set_target_properties(senseimedia senseimediaplugin PROPERTIES
 LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Sensei/Media"
 BUILD_WITH_INSTALL_RPATH ON INSTALL_RPATH "$ORIGIN")
