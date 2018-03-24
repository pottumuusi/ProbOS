#!/bin/bash

install_compilation_tools="y"
install_exec_tools="y"
distro=""

compilation_tools=" nasm xorriso mtools "
exec_tools=" qemu dvd+rw-tools "

tools_to_install=""

handle_args() {
	if [ "-h" == "$1" -o "--help" == "$1" ] ; then
		echo -e "\nOptions:"
		echo -e "\t-c, --nocompile\t\tDo not install compilation tools."
		echo -e "\t-e, --noexec\t\tDo not install execution tools (simulate, burn).\n"
		exit
	fi

	if [ "-c" == "$1" -o "--nocompile" == "$1" ] ; then
		install_compilation_tools="n"
	fi

	if [ "-e" == "$1" -o  "--noexec" == "$1" ] ; then
		install_exec_tools="n"
	fi
}

detect_distro() {
	if [ -n "$(which apt-get 2> /dev/null)" ] ; then
		distro="ubuntu"
	elif [ -n "$(which pacman 2> /dev/null)" ] ; then
		distro="arch"
	else
		echo "Unsupported distribution. Exiting..."
		exit
	fi
}

decide_tools() {
	if [ "y" == "$install_compilation_tools" ] ; then
		tools_to_install+="$compilation_tools"
	fi

	if [ "y" == "$install_exec_tools" ] ; then
		tools_to_install+="$exec_tools"
	fi
}

install_tools() {
	if [ "ubuntu" == "$distro" ] ; then
		sudo apt-get install $tools_to_install
	fi

	if [ "arch" == "$distro" ] ; then
		# sudo pacman -S nasm xorriso mtools qemu dvd+rw-tools
		sudo pacman -S $tools_to_install
	fi

	if [ "y" == "$install_compilation_tools" ] ; then
		if [ -z "$(which rustup 2> /dev/null)" ] ; then
			curl https://sh.rustup.rs -sSf | sh
			source $HOME/.cargo/env
		fi

		# Nightly tools for unstable features
		rustup override add nightly

		if [ -z "$(which xargo 2> /dev/null)" ] ; then
			cargo install xargo
		fi

		# Xargo depends on Rust source code
		rustup component add rust-src
	fi
}

handle_args $1
detect_distro
decide_tools
install_tools
