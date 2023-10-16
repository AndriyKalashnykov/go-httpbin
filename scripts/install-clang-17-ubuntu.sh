#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

sudo apt-get purge -y llvm-17 clang-17
sudo apt autoremove -y

sudo curl -s https://apt.llvm.org/llvm.sh | sudo bash /dev/stdin 17 all

sudo apt-get install -y clang-tidy-17 clang-format-17 libclang-17-dev clang-tools-17 lld-17 libclang-17-dev llvm-17-dev libc++*17-dev libc++abi-*17-dev

# this fixes - /usr/bin/ld: cannot find -lstdc++: No such file or directory (libstdc++-12-dev)
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

sudo update-alternatives --install /usr/local/bin/clang clang /usr/bin/clang-17 99
sudo update-alternatives --install /usr/local/bin/clang++ clang++ /usr/bin/clang++-17 99
sudo update-alternatives --install /usr/local/bin/clang-format clang-format /usr/bin/clang-format-17 99
sudo update-alternatives --install /usr/local/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-17 99
