#!/bin/bash -x

# build.sh
#
# Need to be root when running this script
#
# CSI-230 Fall 2016
#   Brian Baron, Colin Brady, Robert Gentile
#   Justin Mulkin, Gabriel Pereyra, Duncan Carrol, Lucas Spiker
#

if [ ! -e "build.cache" ]
then
	touch build.cache
fi

tinyosc_option="--tinyosc"
libfreenect_option="--freenect"
ofx_option="--ofx"

do_all=1
install_option="--install"
cleanup_option="--cleanup"
mode=0
system="el6"
el6_system="el6"

function install_tinyosc()
{
	if [ "$(grep "tinyosc" build.cache)" != "tinyosc" ]; then
		#patch and compile tinyosc
		./dependencies/$system.sh --install --tinyosc
		pushd ../../tinyosc
		patch build.sh < ../src/scripts/dependencies/tinyosc.build.sh.patch
		./build.sh
		popd
		echo "tinyosc" >> build.cache
	else
		echo "tinyosc already installed"
	fi
}
function cleanup_tinyosc()
{	
	if [ "$(grep "tinyosc" build.cache)" == "tinyosc" ]; then
		./dependencies/$system.sh --install --tinyosc
		sed -i '/tinyosc/d' build.cache
		echo "tinyosc uninstalled"
	else
		echo "tinyosc not installed"
	fi
}

function installOpenFrameworks()
{
	if [ "$(grep "openframeworks" build.cache)" != "openframeworks" ];
	then
		#install dependencies
		echo "running el6.sh"
		./dependencies/$system.sh $cleanup_option $ofx_option
		echo "openframeworks" >> build.cache

		#run install script to openframeworks
		pushd ../../openFrameworks/scripts/linux
		#tells scripts to use 3 cpu cores compile

		#cant actually compile openframeworks as 11/14/16 becuase github master branch doesn't build
		#but it looks like theyre working on fixing

		#./compileOF.sh -j3
		popd
		echo "openframeworks" >> build.cache
	else
		echo "openframeworks already installed"
	fi
}

function cleanOpenFrameworks()
{
	if [ "$(grep "openframeworks" build.cache)" == "openframeworks" ];
	then
		./dependencies/$system.sh --cleanup --ofx
		sed -i '/openframeworks/d' build.cache
		echo "openframeworks cleanup complete"

	else
		echo "openframeworks is not installed"
	fi
}

function install_libfreenect()
{
        if [ "$(grep "libfreenect_" build.cache)" != "libfreenect_" ]
        then
		./dependencies/$system.sh --install --freenect
                #run cmake and make files for libfreenect
                pushd ../../libfreenect
                mkdir build && cd build
                # XXX: BUILD_OPENNI2_DRIVER=ON would work with cmake3 and gcc 4.8+ once installed
                cmake \
                        -DLIBUSB_1_LIBRARY=../../libfreenect2/depends/libusb/lib/libusb-1.0.so \
                        -DLIBUSB_1_INCLUDE_DIR=../../libfreenect2/depends/libusb/include/libusb-1.0 \
                        -DBUILD_OPENNI2_DRIVER=OFF \
                        -L ..
                make
	        make install
        	popd
	        echo "libfreenect_" >> build.cache
        else
                echo "libfreenect already installed"
	fi

}

function cleanup_libfreenect()
{
	if [ "$(grep "libfreenect_" build.cache)" == "openframeworks" ];
	then
		./dependencies/$system.sh --cleanup --freenect
        	#uninstall libfreenect
       		cd ../../../libfreenect/build
        	make uninstall
        	cd ../
        	rm -rf build

       		#remove links created by libfreenect
        	rm -f /usr/local/lib/libfreenect*
        	rm -rf /usr/local/lib/fakenect

		echo "libfreenect uninstalled"
	else
		echo "libfreenect is not installed"
	fi
}

for var in "$@"
do
	if [ $var == $install_option ]; then
		mode=$install_option
	elif [ $var == $cleanup_option ]; then
		mode=$cleanup_option
	elif [ $var == $el6_system ]; then
		system=$el6_system
	elif [ $var == $tinyosc_option ]; then
		tinyosc_option=1
		do_all=0
	elif [ $var == $ofx_option ]; then
		ofx_option=1
		do_all=0
	elif [ $var == $libfreenect_option ]; then
		libfreenect_option=1	
		do_all=0
	fi
done

if [ $tinyosc_option == 1 -o $do_all == 1 ]; then
	if [ $mode == $install_option ]; then
		install_tinyosc
	elif [ $mode == $cleanup_option ]; then
		cleanup_tinyosc
	fi
fi

if [ $ofx_option == 1 -o $do_all == 1 ]; then
	if [ $mode == $install_option ]; then
		installOpenFrameworks
	elif [ $mode == $cleanup_option ]; then
		cleanOpenFrameworks
	fi
fi

if [ $libfreenect_option == 1 -o $do_all == 1 ]; then
	if [ $mode == $install_option ]; then
		install_libfreenect
	elif [ $mode == $cleanup_option ]; then
		cleanup_libfreenect
	fi
fi

