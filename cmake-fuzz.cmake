include_guard()

option(FUZZ "Register fuzzers as tests" OFF)

set(FUZZ_DURATION 120 CACHE STRING "Seconds to run each fuzzer")

function(add_fuzz_executable target)
  set(one_value_keywords
    DURATION
    CORPUS
    CRASHES
  )

  set(multi_value_keywords
    LINK
    LABELS
    PROPERTIES
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
  )

  if(NOT DEFINED cmake_fuzz_supported)
    try_compile(
      cmake_fuzz_supported
      SOURCE_FROM_CONTENT
        entry.c
          "
          #include <stddef.h>
          #include <stdint.h>

          int
          LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {}
          "
      LINK_OPTIONS -fsanitize=fuzzer
    )

    set(cmake_fuzz_supported ${cmake_fuzz_supported} CACHE INTERNAL "Fuzzing supported")
  endif()

  if(cmake_fuzz_supported)
    add_executable(${target} ${ARGV_UNPARSED_ARGUMENTS})
  else()
    add_library(${target} OBJECT ${ARGV_UNPARSED_ARGUMENTS})
  endif()

  target_link_libraries(
    ${target}
    PRIVATE
      ${ARGV_LINK}
  )

  if(NOT cmake_fuzz_supported)
    return()
  endif()

  if(NOT ARGV_DURATION)
    set(ARGV_DURATION ${FUZZ_DURATION})
  endif()

  if(NOT ARGV_CORPUS)
    set(ARGV_CORPUS "${PROJECT_SOURCE_DIR}/test/fuzz/corpus/<TARGET>")
  endif()

  if(NOT ARGV_CRASHES)
    set(ARGV_CRASHES "${PROJECT_SOURCE_DIR}/test/fuzz/crashes/<TARGET>")
  endif()

  foreach(path IN ITEMS ARGV_CORPUS ARGV_CRASHES)
    string(REPLACE "<TARGET>" "${target}" ${path} "${${path}}")

    cmake_path(ABSOLUTE_PATH ${path} NORMALIZE)
  endforeach()

  if(NOT ARGV_LABELS)
    set(ARGV_LABELS fuzz)
  endif()

  # Fuzzers check their results with assert(), which NDEBUG would compile out.
  target_compile_options(
    ${target}
    PRIVATE
      -fsanitize=fuzzer
      -UNDEBUG
  )

  target_link_options(
    ${target}
    PRIVATE
      -fsanitize=fuzzer
  )

  if(NOT FUZZ)
    return()
  endif()

  file(MAKE_DIRECTORY "${ARGV_CORPUS}")
  file(MAKE_DIRECTORY "${ARGV_CRASHES}")

  math(EXPR timeout "${ARGV_DURATION} + 60")

  add_test(
    NAME ${target}
    COMMAND
      ${target}
      "${ARGV_CORPUS}"
      -max_total_time=${ARGV_DURATION}
      -artifact_prefix=${ARGV_CRASHES}/
  )

  set_tests_properties(
    ${target}
    PROPERTIES
      TIMEOUT ${timeout}
      LABELS "${ARGV_LABELS}"
      ENVIRONMENT_MODIFICATION "$<LIST:TRANSFORM,$<TARGET_RUNTIME_DLL_DIRS:${target}>,PREPEND,PATH=path_list_prepend:>"
      ${ARGV_PROPERTIES}
  )
endfunction()

function(add_fuzz_executables)
  set(one_value_keywords
    PREFIX
    DURATION
    CORPUS
    CRASHES
  )

  set(multi_value_keywords
    LINK
    LABELS
    PROPERTIES
  )

  cmake_parse_arguments(
    PARSE_ARGV 0 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
  )

  set(forwarded_arguments)

  foreach(keyword IN LISTS one_value_keywords multi_value_keywords)
    if(keyword STREQUAL "PREFIX" OR NOT DEFINED ARGV_${keyword})
      continue()
    endif()

    list(APPEND forwarded_arguments ${keyword} ${ARGV_${keyword}})
  endforeach()

  foreach(source IN LISTS ARGV_UNPARSED_ARGUMENTS)
    cmake_path(ABSOLUTE_PATH source NORMALIZE OUTPUT_VARIABLE target)
    cmake_path(RELATIVE_PATH target BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    cmake_path(REMOVE_EXTENSION target LAST_ONLY)

    string(REGEX REPLACE "[^A-Za-z0-9_.+-]" "_" target "${ARGV_PREFIX}${target}")

    add_fuzz_executable(${target} ${source} ${forwarded_arguments})
  endforeach()
endfunction()
