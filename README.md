# toppers-asp3-for-linux

Mac OS Xターゲット依存部をLinuxに移植するにあたり、PTR_MANGLEマクロ定義を
glibc-2.22ソースコードから流用している。 これにより，(すくなくともLinux
ターゲット依存部の)コード全体がGPLの適用対象となる可能性がある．
