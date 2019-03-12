macro(configure_msvc_runtime)
  if(MSVC)
    set(MSVC_C_CXX_FLAGS
      CMAKE_C_FLAGS_DEBUG
      CMAKE_C_FLAGS_MINSIZEREL
      CMAKE_C_FLAGS_RELEASE
      CMAKE_C_FLAGS_RELWITHDEBINFO
      CMAKE_CXX_FLAGS_DEBUG
      CMAKE_CXX_FLAGS_MINSIZEREL
      CMAKE_CXX_FLAGS_RELEASE
      CMAKE_CXX_FLAGS_RELWITHDEBINFO
    )
    if("${MSVC_CRT_LINKAGE}" STREQUAL "static")
      set(_add_flag "/MT")
      set(_remove_flag "/MD")
    else()
      set(_add_flag "/MD")
      set(_remove_flag "/MT")
    endif()
    foreach(flag ${MSVC_C_CXX_FLAGS})
      string(REGEX REPLACE ${_remove_flag} ${_add_flag} ${flag} "${${flag}}")
    endforeach()
  endif()
endmacro()


macro(print_link_flags)
  set(MSVC_C_CXX_FLAGS
    CMAKE_C_FLAGS_DEBUG
    CMAKE_C_FLAGS_MINSIZEREL
    CMAKE_C_FLAGS_RELEASE
    CMAKE_C_FLAGS_RELWITHDEBINFO
    CMAKE_CXX_FLAGS_DEBUG
    CMAKE_CXX_FLAGS_MINSIZEREL
    CMAKE_CXX_FLAGS_RELEASE
    CMAKE_CXX_FLAGS_RELWITHDEBINFO
  )
  message(STATUS "Build flags:")
  foreach(flag ${MSVC_C_CXX_FLAGS})
    message(STATUS " ${flag}: ${${flag}}")
  endforeach()
  message(STATUS "")
endmacro()
