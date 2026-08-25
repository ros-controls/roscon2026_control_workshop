cmake_minimum_required(VERSION 3.10)
project(workshop_description)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)

install(
  DIRECTORY ros2_control urdf
  DESTINATION share/workshop_description
)

ament_package()
