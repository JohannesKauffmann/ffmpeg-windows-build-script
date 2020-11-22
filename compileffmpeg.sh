#!/bin/sh

main()
{
    echo "Cross compiling FFmpeg..."

    install_packages

    # Source environment variables and check
    . ./environment-x86_64-w64-mingw32

    init_folders

    # Don't build dependencies if user has answered no 
    build_dependencies
    build_ffmpeg
}


#TODO: Cross compile latest x86_64-w64mingw32-gcc
# Install package dependencies.
# Also installs a newer version of x86_64-w64-mingw32-pkg-config, since the current debian version is broken.
install_packages()
{
    sudo apt install -y gettext m4 nasm yasm autoconf libtool ragel meson ninja-build gperf ant openjdk-11-jdk autogen mercurial && \
    sudo apt install -y mingw-w64-common mingw-w64-x86-64-dev mingw-w64-tools gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 && \
    wget "http://ftp.nl.debian.org/debian/pool/main/m/mingw-w64/mingw-w64-tools_8.0.0-1_amd64.deb" && \
    sudo dpkg -i "mingw-w64-tools_8.0.0-1_amd64.deb" && \
    rm "mingw-w64-tools_8.0.0-1_amd64.deb"
}

# Initialize the dependency folder where all source code is checkout out,
# and the mingw sysroot where everything will be installed.
init_folders()
{
    make_or_prompt_to_clean_folder "$root_dir/dependencies"
    make_or_prompt_to_clean_folder "$SYSROOT"
}

# Check if folder exists. If not, create it. If not, ask the user if they want to clean it, which is the default.
# Either way, the caller can be sure the folder exists afterwards.
make_or_prompt_to_clean_folder()
{
    if [ ! -d "$1" ]; then
        echo "Creating folder $1"
        mkdir $1
    else
        read -p "Do you want to rebuild the dependencies? [Y/n] " rebuild
        case $rebuild in
            [yY]* ) rm -rf $1/*
                    echo "Folder cleaned"
                    break;;

            [nN]* ) echo "Not cleaning folder."
                    break;;

            * )     rm -rf $1/*
                    echo "Folder cleaned"
                    break;;
        esac
    fi
}

# Check if folder exists. If not, create it. If not, clean it.
# Either way, the caller can be sure the folder exists afterwards.
make_or_clean_folder()
{
    if [ ! -d $1 ]; then
        mkdir $1
    else
        rm -rf $1/*
    fi
}

build_dependencies()
{
    echo "Cross compiling dependencies..."
    cd $root_dir/dependencies

    build_gmp
    build_x264
    
    cd ..
    echo "Done compiling dependencies"
}

build_gmp()
{
    wget "https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz"
    tar -xf $( basename "gmp-6.2.1.tar.xz" )
    rm "gmp-6.2.1.tar.xz"
    cd "gmp-6.2.1" && mkdir build && cd build
    ../configure --host=mingw64 --enable-static --disable-shared --prefix=$SYSROOT
    make -j$( nproc )
    make install
    cd ../..
}

build_x264()
{
    git_checkout "https://code.videolan.org/videolan/x264.git" "x264_git" "origin/master"
    mkdir x264_git/build
    cd x264_git/build
    unset AS
    ../configure --enable-static --disable-cli --enable-strip --bit-depth=all --host=$TRIPLET --cross-prefix=$TRIPLET- --prefix=$SYSROOT
    make -j$( nproc )
    make install
    AS=$TRIPLET-as
    cd ../..
}

# Checkout git repository $1 in folder $2, optionally checking out branch $3
git_checkout()
{
    git clone $1 $2
    if [ ! -z "$3" ]; then
        cd $2
        git checkout $3
        cd ..
    fi
}

build_ffmpeg()
{
    echo "Building FFmpeg 4.3.1"
    url="https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.xz"
    dirname=$( basename "$url" ".tar.xz" )
    wget "$url"
    tar -xf "$dirname.tar.xz"
    rm "$dirname.tar.xz"
    mkdir "$dirname/build"
    cd "$dirname/build"
    pkg_config_flags=--static arch=x86_64 target_os=mingw64 cross_prefix=$TRIPLET- ../configure --enable-gpl --enable-version3 --enable-gmp --enable-libx264
    make -j $( nproc )
    cd ../..
    echo "Done building FFmpeg 4.3.1: executable is in ffmpeg-4.3.1/build"
}

set -x
# Pass all arguments to main()
main "$@"