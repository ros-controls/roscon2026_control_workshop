cmake_minimum_required(VERSION 3.16)
project(workshop_controllers LANGUAGES CXX)

if(CMAKE_CXX_COMPILER_ID MATCHES "(GNU|Clang)")
  add_compile_options(-Wall -Wextra -Werror=conversion -Werror=unused-but-set-variable -Werror=return-type -Werror=shadow -Werror=format)
endif()

set(THIS_PACKAGE_INCLUDE_DEPENDS
  controller_interface
  example_interfaces
  pluginlib
  rclcpp
  rclcpp_lifecycle
  realtime_tools
)

find_package(ament_cmake REQUIRED)
find_package(backward_ros REQUIRED)
foreach(Dependency IN ITEMS ${THIS_PACKAGE_INCLUDE_DEPENDS})
  find_package(${Dependency} REQUIRED)
endforeach()


find_package(generate_parameter_library REQUIRED)
generate_parameter_library(sleepy_controller_parameters
  src/sleepy_controller.yaml
)

add_library(workshop_controllers SHARED
  src/sleepy_controller.cpp
)
target_compile_features(workshop_controllers PUBLIC cxx_std_17)
target_include_directories(workshop_controllers PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
)
target_link_libraries(workshop_controllers PUBLIC
  sleepy_controller_parameters
  controller_interface::controller_interface
  rclcpp_lifecycle::rclcpp_lifecycle
  realtime_tools::realtime_tools
  ${example_interfaces_TARGETS}
)

# Causes the visibility macros to use dllexport rather than dllimport,
# which is appropriate when building the dll but not consuming it.
target_compile_definitions(workshop_controllers PRIVATE "_USE_MATH_DEFINES")
pluginlib_export_plugin_description_file(controller_interface controller_plugins.xml)


install(
  DIRECTORY include/
  DESTINATION include/workshop_controllers
)
install(TARGETS
    sleepy_controller_parameters
    workshop_controllers
  EXPORT export_workshop_controllers
  RUNTIME DESTINATION bin
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
)

ament_export_targets(export_workshop_controllers HAS_LIBRARY_TARGET)
ament_export_dependencies(${THIS_PACKAGE_INCLUDE_DEPENDS})
ament_package()
