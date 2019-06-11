# toppers-asp3-for-linux

Mac OS Xターゲット依存部をLinuxに移植するにあたり、PTR_MANGLEマクロ定義を
glibc-2.22ソースコードから流用している。 これにより，(すくなくともLinux
ターゲット依存部の)コード全体がGPLの適用対象となる可能性がある．

## Platform

* Ubuntu 16.04LTS (i386, x64)

## Required packgaes

* gcc-multilib (5.3.1-1ubuntu1)
* ruby (2.3.0+1)

## Quick Start (sample1)
    sudo apt-get install git gcc-multilib ruby
    git clone https://github.com/morioka/toppers-asp3-for-linux
    cd toppers-asp3-for-linux/asp
    mkdir obj
    cd obj
    ../configure.rb -T linux_gcc
    make depend
    make
    ./asp
