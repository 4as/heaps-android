cmake_minimum_required(VERSION 3.1)

project(heapsapp)
add_definitions(-DHL_NO_SSBO)
# Global JIT disable for PCRE2 and other settings
add_definitions(
    -DSUPPORT_JIT=0
    -DPCRE2_SUPPORT_JIT=0
    -DHAVE_CONFIG_H
    -DSUPPORT_PCRE2_16
    -DSUPPORT_UNICODE
    -DLINK_SIZE=2
    -DHAVE_STDLIB_H=1
    -DHAVE_STRING_H=1
    -DHAVE_MEMMOVE=1
    -DHAVE_STDINT_H=1
    -DHAVE_STDLIB_H=1
    -DHAVE_STRING_H=1
    -DHEAP_LIMIT=20000000
    -DMATCH_LIMIT=10000000
    -DMATCH_LIMIT_DEPTH=10000000
    -DMAX_NAME_COUNT=10000
    -DMAX_NAME_SIZE=32
)

include_directories(hashlink/src)

# PCRE2
file(GLOB pcre_src hashlink/include/pcre/pcre2_*.c)
list(REMOVE_ITEM pcre_src
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_jit_compile.c
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_jit_match.c
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_jit_misc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_printint.c
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_jit_test.c
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_dftables.c # Exclude auxiliary program
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_maketables.c # Exclude auxiliary program
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2demo.c # Exclude demo program
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2grep.c # Exclude grep program
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2test.c # Exclude test program
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2posix_test.c # Exclude test program
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_fuzzsupport.c # Exclude fuzzing support
    ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/pcre2_ucptables.c
)
add_library(pcre STATIC ${pcre_src})
target_include_directories(pcre PRIVATE hashlink/include/pcre)
target_compile_definitions(pcre PRIVATE
    PCRE2_CODE_UNIT_WIDTH=16
    SUPPORT_JIT=0
    PCRE2_SUPPORT_JIT=0
    SUPPORT_UNICODE
)

# LibHL
file(GLOB libhl
    hashlink/src/std/*.c
    hashlink/src/gc.c
)
list(REMOVE_ITEM libhl ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/src/std/debug.c)

add_library(hl STATIC
    ${libhl}
    hashlink/src/std/sys_android.c
)

target_link_libraries(hl pcre)

target_compile_definitions(hl PUBLIC
    # Hashlink
    _NO_EXECINFO
    # PCRE2
    PCRE2_CODE_UNIT_WIDTH=16
)

target_include_directories(hl PRIVATE hashlink/include/pcre hashlink/include/pcre/sljit)
target_link_libraries(hl log)

# FMT

set(TJ_LIB ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg-turbo/obj/local/${ANDROID_ABI}/libjpeg-turbo.a)
add_custom_target(turbojpeg
	COMMAND ${ANDROID_NDK}/ndk-build APP_ABI=${ANDROID_ABI} APP_PLATFORM=${ANDROID_PLATFORM} NDK_PROJECT_PATH=${CMAKE_CURRENT_SOURCE_DIR}/libjpeg-turbo
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg-turbo
	BYPRODUCTS ${TJ_LIB}
)

file(GLOB fmt hashlink/libs/fmt/*.c)
file(GLOB png hashlink/include/png/*.c)
file(GLOB zlib hashlink/include/zlib/*.c)
file(GLOB vorbis hashlink/include/vorbis/*.c)
file(GLOB mikkt hashlink/include/mikktspace/*.c)
file(GLOB minimp3 hashlink/include/minimp3/*.c)

add_library(fmt.hdll STATIC
	${fmt}
	${png}	${zlib}
	${vorbis}
	${mikkt}
)

add_dependencies(fmt.hdll turbojpeg)
file(GLOB tj_include libjpeg-turbo/jni/vendor/libjpeg-turbo/libjpeg-turbo-*)
target_link_libraries(fmt.hdll ${TJ_LIB})
target_compile_definitions(fmt.hdll PRIVATE PNG_ARM_NEON_OPT=0 PNG_NO_CONFIG_H) #disable Neon support for now and skip config.h for png

target_include_directories(fmt.hdll PRIVATE
	hashlink/include/png
	hashlink/include/mikktspace
	hashlink/include/minimp3
	hashlink/include/vorbis
	hashlink/include/zlib
    hashlink/include/pcre
	${tj_include}
)

# SDL

set(CMAKE_ANDROID_API_MIN 24) # Set minimum Android API level for SDL2
add_subdirectory(sdl2)
file(GLOB sdl hashlink/libs/sdl/*.c)
add_library(sdl.hdll STATIC ${sdl})
target_compile_definitions(sdl.hdll PRIVATE HL_NO_SSBO GL_GLES_PROTOTYPES=1 SDL_GLES_VERSION=3)
target_include_directories(sdl.hdll PUBLIC sdl2/include)
target_link_libraries(sdl.hdll SDL2 SDL2main EGL GLESv3)

# OpenAL

set(CMAKE_ANDROID_API=23)
# configure_file(${CMAKE_CURRENT_SOURCE_DIR}/openal-nativetools/CMakeLists.txt ${CMAKE_CURRENT_SOURCE_DIR}/openal-soft COPYONLY)
set(ALSOFT_UTILS OFF CACHE BOOL "Don't build OpenAL utils" FORCE)
set(ALSOFT_EXAMPLES OFF CACHE BOOL "Don't build OpenAL examples" FORCE)
set(ALSOFT_TESTS OFF CACHE BOOL "Don't build OpenAL tests" FORCE)
add_definitions(-DHAVE_LOG2F -DHAVE_CBRTF -DHAVE_COPYSIGNF -DHAVE_C11_ALIGNAS=1)
add_subdirectory(openal-soft)
# We'll define a variable for OpenAL_SOURCE_DIR here to ensure the include directories are correct for OpenAL Soft
set(OpenAL_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openal-soft)
target_compile_definitions(OpenAL PUBLIC -DHAVE_GCC_DESTRUCTOR=1 -D_DEFAULT_SOURCE=1 -DHAVE_DIRENT_H=1)

# UI

file(GLOB ui hashlink/libs/ui/ui_stub.c)
add_library(ui.hdll STATIC ${ui})

# SSL (MbedTLS)
file(GLOB ssl_hl_src hashlink/libs/ssl/*.c)
file(GLOB mbedtls_src hashlink/include/mbedtls/library/*.c)
list(REMOVE_ITEM mbedtls_src ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/mbedtls/library/arc4.c)

add_library(ssl.hdll STATIC
    ${ssl_hl_src}
    ${mbedtls_src}
)
target_include_directories(ssl.hdll PRIVATE hashlink/include/mbedtls/include)

# UV (libuv)
set(libuv_root hashlink/include/libuv)
file(GLOB uv_hl_src hashlink/libs/uv/*.c)
set(uv_common_src
        ${libuv_root}/src/fs-poll.c
        ${libuv_root}/src/inet.c
        ${libuv_root}/src/threadpool.c
        ${libuv_root}/src/uv-common.c
        ${libuv_root}/src/version.c
)
set(uv_unix_src
        ${libuv_root}/src/unix/async.c
        ${libuv_root}/src/unix/core.c
        ${libuv_root}/src/unix/dl.c
        ${libuv_root}/src/unix/fs.c
        ${libuv_root}/src/unix/getaddrinfo.c
        ${libuv_root}/src/unix/getnameinfo.c
        ${libuv_root}/src/unix/loop-watcher.c
        ${libuv_root}/src/unix/loop.c
        ${libuv_root}/src/unix/pipe.c
        ${libuv_root}/src/unix/poll.c
        ${libuv_root}/src/unix/process.c
        ${libuv_root}/src/unix/signal.c
        ${libuv_root}/src/unix/stream.c
        ${libuv_root}/src/unix/tcp.c
        ${libuv_root}/src/unix/thread.c
        ${libuv_root}/src/unix/timer.c
        ${libuv_root}/src/unix/tty.c
        ${libuv_root}/src/unix/udp.c
        ${libuv_root}/src/unix/linux-core.c
        ${libuv_root}/src/unix/linux-inotify.c
        ${libuv_root}/src/unix/linux-syscalls.c
        ${libuv_root}/src/unix/proctitle.c
        ${libuv_root}/src/unix/android-ifaddrs.c
        ${libuv_root}/src/unix/android-compat.c
)

add_library(uv.hdll STATIC
    ${uv_hl_src}
    ${uv_common_src}
    ${uv_unix_src}
)
target_compile_definitions(uv.hdll PRIVATE _GNU_SOURCE _LARGEFILE_SOURCE _FILE_OFFSET_BITS=64)
target_include_directories(uv.hdll PRIVATE ${libuv_root}/include ${libuv_root}/src)

# Heaps Application
file(GLOB openal_hl_src hashlink/libs/openal/*.c)
add_library(heapsapp SHARED
    out/game.c
    stubs.c
    ${openal_hl_src}
)
target_include_directories(heapsapp PRIVATE out ${OpenAL_SOURCE_DIR}/include hashlink/include/pcre)
target_compile_definitions(heapsapp PRIVATE
        # Hashlink
        _NO_EXECINFO
        # libuv
        _GNU_SOURCE _LARGEFILE_SOURCE _FILE_OFFSET_BITS=64
        # PNG
        PNG_ARM_NEON_OPT=0
        # SDL Entry Point
        HL_MOBILE
        sdl__Sdl__val
)
target_link_libraries(heapsapp
    hl
    sdl.hdll
    fmt.hdll
    ui.hdll
    ssl.hdll
    uv.hdll
    EGL
    GLESv3
    OpenSLES
    log
    android
    OpenAL # Moved OpenAL after system libraries
    pcre
)
