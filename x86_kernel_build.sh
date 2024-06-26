#!/bin/sh

##############################################
############     READ This  ##################
# Run the below command, output of this script file is copied in to "kernel_build.log" file it is useful for further analysis.
# $ ./x86_kernel_build.sh | tee kernel_build.log
##############################################


# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
NC='\033[0m'              # No Color
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White
BRedU='\033[4;31m'         # Underline


echo "${BRed}${BRedU}Step1: Setup kernel build Environment${NC}"
echo ""
echo "${Green}-----------------------------"
echo -n ${Red}"Check No. of CPUS:${NC}"
export cpus=`cat /proc/cpuinfo | grep processor | wc -l`
echo $cpus
echo "${Green}-----------------------------${NC}"
echo ""; echo ""


dpkg -s bison > /dev/zero
if [ $? -eq 0 ]; then
    echo "bison Package  is installed!"
else
    echo "${Red}bison Package  is NOT installed!${NC}"
    sudo apt install bison
fi
dpkg -s flex > /dev/zero
if [ $? -eq 0 ]; then
    echo "flex Package  is installed!"
else
    echo "${Red}flex Package  is NOT installed!${NC}"
    sudo apt install flex
fi

dpkg -s make > /dev/zero
if [ $? -eq 0 ]; then
    echo "make Package  is installed!"
else
    echo "${Red}make Package  is NOT installed!${NC}"
    sudo apt install make
fi

dpkg -s libssl-dev > /dev/zero
if [ $? -eq 0 ]; then
    echo "libssl-dev Package  is installed!"
else
    echo "${Red}libssl-dev Package  is NOT installed!${NC}"
    sudo apt install libssl-dev
fi


dpkg -s ncurses-dev > /dev/zero
if [ $? -eq 0 ]; then
    echo "ncurses-dev Package  is installed!"
else
    echo "${Red}ncurses-dev Package  is NOT installed!${NC}"
    sudo apt install ncurses-dev
fi

dpkg -s dwarves > /dev/zero
if [ $? -eq 0 ]; then
    echo "dwarves Package  is installed!"
else
    echo "${Red}dwarves Package  is NOT installed!${NC}"
    sudo apt install dwarves
fi

echo "${BRed}${BRedU}Step2: Configure Kernel${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Check .config file:"
echo "${Green}-----------------------------${NC}"

if [ -f .config ] ; then
	echo "${Red}~/.config file found.[Kernel Configuration has DONE]"
        echo "If you want to configure the kernel again type \"yes\" otherwise \"no\" to skip kernel configuration${NC}"
	read  temp
	if [ $temp = "yes" ];then
	make  menuconfig
	fi
else
	echo "${Green}~/.config file not found [Kernel Configuration has not done]."
       	echo "Please configure the kernel for further steps.${NC}"
	cp /boot/config-`uname -r` .config
	x=5
	while [ "$x" -ne 0 ]; do
		echo -n "$x "
		x=$(($x-1))
		sleep 1
	done
	echo "${Purple}make menuconfig${NC}"
	make  menuconfig
	if [ -f .config ] ; then
		echo "${Green}Kernel Configuration has done successfully"
	else
		echo "${Red}Kernel Configuration is not done. exit here"
		exit 0
	fi
	scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
fi
echo ""; echo ""

echo "${BRed}${BRedU}Step3: Compile Kernel ${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Compile static Kernel. [vmlinux]"
echo "${Green}-----------------------------${NC}"
echo "${Purple}make -j${cpus}${NC}"
make -j${cpus}
if [ $? -ne 0 ]
then
	echo "";echo ""
	echo "${Red}Kernel Static Compilation FAIL${NC}"
	exit 0
fi

echo ""; echo ""

echo "${Green}-----------------------------"
echo "${Red}Compile Kernel Modules [.ko]"
echo "${Green}-----------------------------${NC}"
echo "${Purple}make modules -j${cpus}${NC}"
make modules -j${cpus}
if [ $? -ne 0 ]
then
	echo "";echo ""
	echo "${Red}Kernel Module Compilation FAIL${NC}"
	exit 0
fi
echo "${Red}Size of kernel source folder after Kernel compilation"
echo "${Purple}du -sh ."
du -sh .
echo ""; echo ""

echo "${BRed}${BRedU}Step4: Install Kernel${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Install Kernel Modules."
echo "${Green}-----------------------------${NC}"
echo "${Purple}sudo make modules_install  -j${cpus}${NC}"
sudo make modules_install -j${cpus}
if [ $? -ne 0 ]
then
	echo "";echo ""
	echo "${Red}Kernel Module Installation FAIL${NC}"
	exit 0
fi
echo ""; echo ""

echo "${Green}-----------------------------"
echo "${Red}Install vmlinux"
echo "${Green}-----------------------------${NC}"
echo "${Purple}sudo make install ${NC}"
sudo make install
if [ $? -ne 0 ]
then
	echo "";echo ""
	echo "${Red}Kernel Static Compilation FAIL${NC}"
	exit 0
fi
echo ""; echo ""

	echo "${Purple}Successfully Installed Own built kernel."
	echo "If you want to enter new kernel to reboot system,Press yes or no${NC}"
	read temp
	if [ $temp = "yes" ]; then
		echo "${Red}reboot ...${NC}"
	        sudo reboot
        else
		echo "${Greem}script done${NC}"
	fi
