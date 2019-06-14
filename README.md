# toppers-asp3-for-linux

https://www.toppers.jp/asp3-kernel.html

## Platform

* Ubuntu 16.04LTS (i386, x64)
  * 32bit binary available
  * 64bit binary available also
 
## Required packgaes

* gcc-multilib (5.3.1-1ubuntu1)
* ruby (2.3.0+1)

## Notice

"glibc_sysdep.h" contains PTR_MANGLE definitions from glibc sysdep.h (i386, x86_64).

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
