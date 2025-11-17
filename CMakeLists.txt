cmake_minimum_required(VERSION 3.16)
project(trdp LANGUAGES C)

set(TRDP_ARCHIVE "${CMAKE_SOURCE_DIR}/trdp-2.0.3.0.tar.gz")
if(NOT EXISTS "${TRDP_ARCHIVE}")
    message(FATAL_ERROR "Missing ${TRDP_ARCHIVE}. The upstream TRDP archive must be present at configure time.")
endif()

set(TRDP_BUILD_DIR "${CMAKE_BINARY_DIR}")
set(TRDP_SOURCE_DIR "${TRDP_BUILD_DIR}/trdp")
set(TRDP_PATCH_STAMP "${TRDP_SOURCE_DIR}/.patches-applied")

# Ensure the reference sources are extracted before we discover files.
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env TRDP_BUILD_DIR=${TRDP_BUILD_DIR} ${CMAKE_SOURCE_DIR}/tools/prepare_sources.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE PREPARE_EXIT_CODE
)
if(NOT PREPARE_EXIT_CODE EQUAL 0)
    message(FATAL_ERROR "Failed to prepare the TRDP sources (exit code ${PREPARE_EXIT_CODE}).")
endif()

file(GLOB PATCH_FILES RELATIVE ${CMAKE_SOURCE_DIR} "patches/*.patch")
list(TRANSFORM PATCH_FILES PREPEND "${CMAKE_SOURCE_DIR}/")

add_custom_command(
    OUTPUT ${TRDP_PATCH_STAMP}
    COMMAND ${CMAKE_COMMAND} -E env TRDP_BUILD_DIR=${TRDP_BUILD_DIR} ${CMAKE_SOURCE_DIR}/tools/prepare_sources.sh
    DEPENDS ${TRDP_ARCHIVE} ${CMAKE_SOURCE_DIR}/tools/prepare_sources.sh ${PATCH_FILES}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Preparing TRDP sources"
    VERBATIM
)
add_custom_target(trdp_prepare DEPENDS ${TRDP_PATCH_STAMP})

# Collect sources from the prepared tree.
file(GLOB TRDP_COMMON_SOURCES CONFIGURE_DEPENDS "${TRDP_SOURCE_DIR}/src/common/*.c")
file(GLOB TRDP_VOS_COMMON_SOURCES CONFIGURE_DEPENDS "${TRDP_SOURCE_DIR}/src/vos/common/*.c")
set(TRDP_VOS_POSIX_SOURCES
    "${TRDP_SOURCE_DIR}/src/vos/posix/vos_shared_mem.c"
    "${TRDP_SOURCE_DIR}/src/vos/posix/vos_sock.c"
    "${TRDP_SOURCE_DIR}/src/vos/posix/vos_thread.c"
)
set(TRDP_CORE_SOURCES
    ${TRDP_COMMON_SOURCES}
    ${TRDP_VOS_COMMON_SOURCES}
    ${TRDP_VOS_POSIX_SOURCES}
)

add_library(trdp_core STATIC ${TRDP_CORE_SOURCES})
add_dependencies(trdp_core trdp_prepare)

find_package(LibXml2 REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Threads REQUIRED)
find_library(UUID_LIBRARY uuid REQUIRED)
find_library(RT_LIBRARY rt)
find_library(M_LIBRARY m)

target_include_directories(trdp_core PUBLIC
    ${TRDP_SOURCE_DIR}/src/api
    ${TRDP_SOURCE_DIR}/src/common
    ${TRDP_SOURCE_DIR}/src/vos/api
    ${TRDP_SOURCE_DIR}/src/vos/posix
    ${TRDP_SOURCE_DIR}/src/vos/common
)
target_compile_definitions(trdp_core PUBLIC MD_SUPPORT=1 HAS_UUID POSIX _GNU_SOURCE O_LE TRDP_MD_AUTOPAD)
target_link_libraries(trdp_core PUBLIC LibXml2::LibXml2)

set(COMMON_LIBS ${UUID_LIBRARY} Threads::Threads)
if(RT_LIBRARY)
    list(APPEND COMMON_LIBS ${RT_LIBRARY})
endif()
if(M_LIBRARY)
    list(APPEND COMMON_LIBS ${M_LIBRARY})
endif()

add_executable(trdp-xmlpd-test "${TRDP_SOURCE_DIR}/test/xml/trdp-xmlpd-test.c")
target_link_libraries(trdp-xmlpd-test PRIVATE trdp_core ZLIB::ZLIB ${COMMON_LIBS})

add_executable(trdp-xmlprint "${TRDP_SOURCE_DIR}/test/xml/trdp-xmlprint-test.c")
target_link_libraries(trdp-xmlprint PRIVATE trdp_core ZLIB::ZLIB ${COMMON_LIBS})

add_executable(trdp-pd-test "${TRDP_SOURCE_DIR}/test/pdpatterns/trdp-pd-test.c")
target_link_libraries(trdp-pd-test PRIVATE trdp_core ${COMMON_LIBS})

add_custom_target(prepare_sources DEPENDS trdp_prepare)
