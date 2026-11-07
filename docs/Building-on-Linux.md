Before compiling FSO you need to install the required libraries. The exact names of the packages depend on your distribution. This list is not complete, please let us know which packages you needed if you compiled FSO on another distribution. This guide is aimed at people with less experience with compiling projects so if you already know how to do that you can probably skip a lot of these steps.

## Ubuntu 18.04+ (and derivatives)
    apt-get install libopenal-dev build-essential cmake libsdl2-dev libpng-dev libjpeg62-dev liblua5.1-0-dev libjansson-dev libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libswscale-dev libfreetype6-dev libfreetype-dev libxcb-glx0-dev

## Fedora (22+)
    dnf install openal-devel gcc gcc-c++ cmake SDL2-devel compat-lua-devel libpng-devel libjpeg-devel jansson-devel ffmpeg-devel freetype-devel libxcb-devel

# Compiling
FSO uses CMake to generate the make files for compiling the project ([Ninja](https://ninja-build.org/) works as well, add ```-G Ninja``` to your cmake command). Open a terminal and navigate to the source code checkout:

    cd <source code dir>

Create a new directory for CMake to generate the Make files in and change to that directory (the name is not important but it shouldn't be an existing directory).

    mkdir build
    cd build

You are now able generate the Make file with CMake with a command similar to `cmake ..`. However, before doing that you may want to customize the build process a bit. By setting special command line options for CMake you can influence how the Make files are generated. These variables are listed in the Readme of the main repository. If you just want to get an FSO executable then you probably want to set the `FSO_FREESPACE_PATH` variable to the path of your FS2 install. That will enable you to automatically install the executables to that path. If you don't want this you can just run the command from above.

    cmake -DFSO_FREESPACE_PATH=<fs2 path> ..



**WARNING**

If you intend to redistribute the binaries you build, you must use the LGPL libraries of FFmpeg. We have prebuilt libraries for that which will be downloaded by CMake if the FFmpeg libraries aren't installed. You can force this by passing the `FFMPEG_USE_PRECOMPILED` option to CMake:

    cmake <other options> -DFFMPEG_USE_PRECOMPILED=ON .

**WARNING**

This will generate the Make files. If everything went well the last line in the terminal should be

    -- Build files have been written to: <build directory>

If you want to compile a debug executable, run this cmake command:

    cmake -DCMAKE_BUILD_TYPE=Debug -DFSO_FREESPACE_PATH=<fs2 path> ..

Now you are finally ready to compile the executables. To speed up the build `make` you can use the `-j<N>` option where `<N>` equals the number of cores your CPU has:

    make -j<N> install

This will take a while, depending on how fast your CPU is. If everything went well this will end with the installation of the compiled exeutables:

    Install the project...
    -- Install configuration: "Release"
    -- Installing: <fs2 path>/./fs2_open_3_7_5_x64

That's it! You now have your executable that you can use either directly or with wxLauncher.