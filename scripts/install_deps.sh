#!/bin/bash

repo_root=$(cd .. && pwd)

if [ -z "$(echo $(basename ${repo_root}) | grep -i probos)" ] ; then
	echo -n "Script is being run from unexpected directory. "
	echo "Please run from scripts/ of probos project."
	exit
fi

install_compilation_tools="y"
install_build_tools="y"
install_exec_tools="y"
distro=""

compilation_tools=" nasm xorriso mtools "
exec_tools=" qemu dvd+rw-tools "

tools_to_install=""

error_exit() {
	echo "$1 ==> Exiting"
	exit 1
}

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

	if [ "-e" == "$1" -o  "--nobuild" == "$1" ] ; then
		install_build_tools="n"
	fi
}

detect_distro() {
	if [ -n "$(which apt-get 2> /dev/null)" ] ; then
		distro="ubuntu"
	elif [ -n "$(which pacman 2> /dev/null)" ] ; then
		distro="arch"
	else
		error_exit "Unsupported distribution."
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
	if [ -n "$tools_to_install" ] ; then
		if [ "ubuntu" == "$distro" ] ; then
			sudo apt-get install $tools_to_install
		fi

		if [ "arch" == "$distro" ] ; then
			# sudo pacman -S nasm xorriso mtools qemu dvd+rw-tools
			sudo pacman -S $tools_to_install
		fi
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

	if [ "y" == "$install_build_tools" ] ; then
		local make_version="3.79.1"
		local remote_make_dirname="make-${make_version}"
		local remote_make_tar="${remote_make_dirname}.tar.gz"
		local make_build_dir="build_make_here"
		local old_make_build_dir="build_old_make_here"
		local old_make_out_dir="${repo_root}/deps/old_make"
		local old_make_out_bin="${repo_root}/deps/old_make/bin/make3791"
		local make_out_dir="${repo_root}/deps/make"
		local make_url="http://ftp.gnu.org/gnu/make/${remote_make_tar}"

		pushd ./
		if [ ! -d "${old_make_build_dir}" ] ; then
			mkdir ${old_make_build_dir}
		fi
		if [ ! -d "${make_build_dir}" ] ; then
			mkdir ${make_build_dir}
		fi
		cd ${old_make_build_dir} && wget ${make_url}
		tar -xzvf ${remote_make_tar}
		cd ${remote_make_dirname}
		patch glob/glob.c < ${repo_root}/scripts/patches/glob_glob_dot_c_patch.diff
		if [ ! -d "${old_make_out_dir}" ] ; then
			mkdir -p ${old_make_out_dir}
		fi
		if [ ! -d "${make_out_dir}" ] ; then
			mkdir -p ${make_out_dir}
		fi
		./configure \
			--prefix=${old_make_out_dir} \
			--exec-prefix=${old_make_out_dir} \
			--program-suffix=3791 \
			&& sh build.sh \
			&& ./make install
		popd
		pushd ./
		cd ${make_build_dir}
		git clone git://git.savannah.gnu.org/make.git && cd make
		#### _____ Checkout to following commit ____
		#### commit 214865ed5c66d8e363b16ea74509f23d93456707 (HEAD -> master, origin/master, origin/HEAD)
		#### Author: Paul Smith <psmith@gnu.org>
		#### Date:   Sun Sep 16 01:09:10 2018 -0400

		####     * src/arscan.c (ar_member_touch): [SV 54533] Stop \0 in archive headers

		####     diff --git a/src/arscan.c b/src/arscan.c
		git checkout 214865e
		./bootstrap || error_exit "Bootstrap failed"
		./configure \
			--prefix=${make_out_dir} \
			--exec-prefix=${make_out_dir} \
			--program-suffix=42 \
			&& ${old_make_out_bin} check \
			&& ${old_make_out_bin} install
		popd
	fi
}

handle_args $1
detect_distro
decide_tools
install_tools
