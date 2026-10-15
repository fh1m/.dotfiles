cmake_minimum_required(VERSION 3.20)
project(sensei_context_guard LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Gui Quick)
add_library(sensei_context_guard MODULE plugin.cpp)
target_link_libraries(sensei_context_guard PRIVATE Qt6::Gui Qt6::Quick)
set_target_properties(sensei_context_guard PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/generic")
add_executable(context_guard_test test.cpp)
target_link_libraries(context_guard_test PRIVATE Qt6::Gui Qt6::Quick)
# assert() must remain active in Release builds too.
target_compile_options(context_guard_test PRIVATE -UNDEBUG)
enable_testing()
add_test(NAME context_guard COMMAND context_guard_test)
set_tests_properties(context_guard PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")

add_test(NAME context_guard_plugin_lifecycle COMMAND context_guard_test --plugin-only)
set_tests_properties(context_guard_plugin_lifecycle PROPERTIES ENVIRONMENT
    "QT_QPA_PLATFORM=offscreen;QT_PLUGIN_PATH=${CMAKE_BINARY_DIR};QT_QPA_GENERIC_PLUGINS=sensei-context-guard")
