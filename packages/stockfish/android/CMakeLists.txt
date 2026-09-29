cmake_minimum_required(VERSION 3.4.1)

project(stockfish)

add_link_options(-Wl,-z,max-page-size=16384)
add_link_options(-Wl,-z,common-page-size=16384)

file(GLOB_RECURSE cppPaths
    "../ios/Stockfish/src/*.cpp"
)

add_library(
    stockfish
    SHARED
    ../ios/FlutterStockfish/ffi.cpp
    ${cppPaths}
)

if(ANDROID_ABI STREQUAL "arm64-v8a")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_options(
            stockfish
            PRIVATE
            -DNNUE_EMBEDDING_OFF
            -DUSE_PTHREADS
            -DIS_64BIT
            -DUSE_POPCNT
            -DUSE_NEON=8
        )
    else()
        target_compile_options(
            stockfish
            PRIVATE
            -DNNUE_EMBEDDING_OFF
            -fno-exceptions
            -DUSE_PTHREADS
            -DNDEBUG
            -O3
            -DIS_64BIT
            -DUSE_POPCNT
            -DUSE_NEON=8
        )
    endif()
else()
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_options(
            stockfish
            PRIVATE
            -DNNUE_EMBEDDING_OFF
            -DUSE_PTHREADS
        )
    else()
        target_compile_options(
            stockfish
            PRIVATE
            -DNNUE_EMBEDDING_OFF
            -fno-exceptions
            -DUSE_PTHREADS
            -DNDEBUG
            -O3
        )
    endif()
endif()
