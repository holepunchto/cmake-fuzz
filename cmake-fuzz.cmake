include_guard()

option(FUZZ "Register fuzzers as tests" OFF)

set(FUZZ_DURATION 120 CACHE STRING "Seconds to run each fuzzer")

function(add_fuzzer target)
  set(one_value_keywords
    CORPUS
    CRASHES
    DURATION
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" ""
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

  if(NOT cmake_fuzz_supported)
    add_library(${target} OBJECT ${ARGV_UNPARSED_ARGUMENTS})

    return()
  endif()

  add_executable(${target} ${ARGV_UNPARSED_ARGUMENTS})

  target_compile_options(
    ${target}
    PRIVATE
      -fsanitize=fuzzer
  )

  target_link_options(
    ${target}
    PRIVATE
      -fsanitize=fuzzer
  )

  if(FUZZ)
    if(NOT ARGV_CORPUS)
      set(ARGV_CORPUS "${PROJECT_SOURCE_DIR}/test/fuzz/corpus/${target}")
    endif()

    if(NOT ARGV_CRASHES)
      set(ARGV_CRASHES "${PROJECT_SOURCE_DIR}/test/fuzz/crashes/${target}")
    endif()

    file(MAKE_DIRECTORY "${ARGV_CORPUS}")
    file(MAKE_DIRECTORY "${ARGV_CRASHES}")

    if(NOT ARGV_DURATION)
      set(ARGV_DURATION ${FUZZ_DURATION})
    endif()

    math(EXPR fuzz_timeout "${ARGV_DURATION} + 60")

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
        LABELS fuzz
        TIMEOUT ${fuzz_timeout}
    )
  endif()
endfunction()
