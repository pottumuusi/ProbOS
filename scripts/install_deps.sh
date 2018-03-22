#!/bin/bash

sudo pacman -S nasm xorriso mtools qemu dvd+rw-tools
curl https://sh.rustup.rs -sSf | sh
rustup override add nightly # Nightly tools for unstable features
cargo install xargo
