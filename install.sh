#!/bin/bash

export LC_ALL=C

# patch function: find line containing <string start>, search for line containing <string end>, insert last argument as line before end
# <filename> <string start> <string end> <string to insert before end>
function insert2file {
        found=0
        ok=0
        while IFS= read -r line
        do
                if [[ "$line" =~ "$2" ]]; then
                        found=1
                fi
                if [[ "$line" =~ "$3" ]]; then
                        if [[ $found == 1 ]]; then
                                printf "$4\n"
                                ok=1
                        fi
                        found=0
                fi
                echo "$line"
        done < $1 >/tmp/patch.tmp
        /bin/mv -f /tmp/patch.tmp $1

        if [[ $ok == 0 ]]; then
                echo -e "$ERR Error: Patch failed! $1 $NC" 1>&2
                whiptail --title "Error" --msgbox "Patch failed! $1" 10 60
                exit 1
        fi
}

# patch function: replaces <search> with <replace> 
# <filename> <search> <replace>
function patchfile {
        sed -i "s/$2/$3/w /tmp/changelog.txt" $1
        if [[ ! -s /tmp/changelog.txt ]]; then
                echo -e "$ERR Error: Patch failed! $1 $NC" 1>&2
                whiptail --title "Error" --msgbox "Patch failed! $1" 10 60
                exit 1
        fi
}


REPORAW="https://raw.githubusercontent.com/Craniun/empc-arpi3-linux-drivers/master"

ERR='\033[0;31m'
INFO='\033[0;32m'
NC='\033[0m' # No Color

if [ $EUID -ne 0 ]; then
    echo -e "$ERR ERROR: This script should be run as root. $NC" 1>&2
    exit 1
fi

if test -e /opt/janztec/empc-arpi3-linux-drivers/installdrivers.sh; then
    echo -e "$ERR ERROR: This script is not supported on images with pre-installed driver installation script. Use script /opt/janztec/empc-arpi3-linux-drivers/installdrivers.sh , or contact Janz Tec support for new image download. $NC" 1>&2
    exit 1
fi

wget -q --spider https://www.github.com
if [ $? -ne 0 ]; then
        echo -e "$ERR ERROR: Internet connection required! $NC" 1>&2
        exit 1
fi

lsb_release -a 2>1 | grep "Raspbian GNU/Linux" || (echo -e "$ERR ERROR: Raspbian GNU/Linux required! $NC" 1>&2; exit 1;)

KERNEL=$(uname -r)

VERSION=$(echo $KERNEL | cut -d. -f1)
PATCHLEVEL=$(echo $KERNEL | cut -d. -f2)
SUBLEVEL=$(echo $KERNEL | cut -d. -f3 | cut -d- -f1)

KERNELVER=$(($VERSION*100+$PATCHLEVEL));

if [ $KERNELVER -le 408 ]; then 
 echo -e "$ERR WARNING: kernel is outdated - $NC" 1>&2
 if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "WARNING: kernel is outdated ($KERNEL < 4.9.0)\n\nDo you want to continue anyway?" 10 60) then
    echo ""
 else
   exit 0
 fi
fi

YEAR=$[`date +'%Y'`]
if [ $YEAR -le 2020 ] ; then
        echo -e "$ERR ERROR: invalid date. set current date and time! $NC" 1>&2
        exit 1
fi

FREE=`df $PWD | awk '/[0-9]%/{print $(NF-2)}'`
if [[ $FREE -lt 1048576 ]]; then
  echo -e "$ERR ERROR: 1GB free disk space required (run raspi-config, 'Expand Filesystem') $NC" > /dev/stderr
  exit 1
fi

KERNEL=$(uname -r)

clear
WELCOME="These drivers will be compiled and installed:\n
- CAN driver (SocketCAN)
- Serial driver (RS232/RS485)
- SPI driver\n
- libncurses5-dev, gcc, build-essential, raspberrypi-kernel-headers, lib, autoconf, libtool, libsocketcan, can-utils\n
continue installation?"

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$WELCOME" 20 60) then
    echo ""
else
    exit 0
fi


#if [ "$VERSION" == "5" ] && [ $PATCHLEVEL -ge 10 ]; then
        # For Linux kernel 5.10.0+

        # get installed gcc version
        #GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
        # get gcc version of installed kernel
        #GCCVER=$(cat /proc/version | egrep -o 'arm-linux-gnueabihf-gcc-[0-9]+' | egrep -o '[0-9.]+')
#else
        # For Linux kernel 4.0.0+

        # get installed gcc version
        #GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
        # get gcc version of installed kernel
        #GCCVER=$(cat /proc/version | egrep -o 'gcc version [0-9]+\.[0-9]+' | egrep -o '[0-9.]+')
#fi

apt-get update -y

clear
HEADERS_TOOLS="Do you want to install the latest kernel headers and build tools?:\n
These software components will be installed if you select yes:\n
- raspberrypi-kernel-headers
- build-essential
- libncurses5-dev
- bc
- device-tree-compiler
- gcc
- g++
If you select no, we assume that you have already installed the appropriate headers and tools."

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$HEADERS_TOOLS" 20 60) then
        apt-get -y install libncurses5-dev bc build-essential raspberrypi-kernel-headers device-tree-compiler gcc g++

        headerversion=$(dpkg -l | grep raspberrypi-kernel-headers | awk '{ print $3 }')
        kernelversion=$(dpkg -l | grep raspberrypi-kernel | grep bootloader | awk '{ print $3 }')

        if [ "$headerversion" == "$kernelversion" ]; then
                echo -e "$INFO INFO: found kernel header version $headerversion $NC" 1>&2
        else
                echo -e "$ERR WARNING: kernel is outdated! use 'apt-get install raspberrypi-kernel' to install latest kernel. Then reboot and run this script again - $NC" 1>&2
                exit 1
        fi
else
        headerversion=$(dpkg -l | grep raspberrypi-kernel-headers | awk '{ print $3 }')
        kernelversion=$(dpkg -l | grep raspberrypi-kernel | grep bootloader | awk '{ print $3 }')

        if [ "$headerversion" == "$kernelversion" ]; then
                echo -e "$INFO INFO: found kernel header version $headerversion $NC" 1>&2
        else
                echo -e "$ERR WARNING: linux kernel version and kernel header version do not match! - $NC" 1>&2 
                echo -e "$ERR Please install matching versions or run the install script again and select yes for installing kernel headers. - $NC" 1>&2
                exit 1
        fi
fi



#if [ ! -f "/usr/bin/gcc-$GCCVER" ] || [ ! -f "/usr/bin/g++-$GCCVER" ]; then
#    echo "no such version gcc/g++ $GCCVER installed" 1>&2
#    exit 1
#fi

#update-alternatives --remove-all gcc 
#update-alternatives --remove-all g++

#update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCCVERBACKUP 10
#update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCCVERBACKUP 10

#update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCCVER 50
#update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCCVER 50

#update-alternatives --set gcc "/usr/bin/gcc-$GCCVER"
#update-alternatives --set g++ "/usr/bin/g++-$GCCVER"


rm -rf /tmp/empc-arpi-linux-drivers
mkdir -p /tmp/empc-arpi-linux-drivers
cd /tmp/empc-arpi-linux-drivers


# compile driver modules

wget -nv https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git/plain/drivers/net/can/spi/mcp251x.c?h=v$VERSION.$PATCHLEVEL.$SUBLEVEL -O mcp251x.c
wget -nv https://raw.githubusercontent.com/Craniun/empc-arpi3-linux-drivers/master/src/sc16is7xx.c -O sc16is7xx.c
wget -nv https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git/plain/drivers/spi/spi-bcm2835.c?h=v$VERSION.$PATCHLEVEL.$SUBLEVEL -O spi-bcm2835.c


OPTIMIZATIONS="Optimizations of mainline drivers are available:\n
- SPI driver (spi-bcm2835.c)
 - higher polling time limit for lower latency
 - enable real time priority for work queue\n
- SocketCan driver (mcp251x.c)
 - higher ost delay timeout to prevent can detection problems after soft-reboots\n
 - use low level interrupts
\nDo you want these optimizations?"

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$OPTIMIZATIONS" 24 60) then

        sed -i 's/MODULE_DESCRIPTION("/MODULE_DESCRIPTION("optimized for emPC-A\/RPI3: /' spi-bcm2835.c
        sed -i 's/MODULE_DESCRIPTION("/MODULE_DESCRIPTION("optimized for emPC-A\/RPI3: /' mcp251x.c
        sed -i 's/MODULE_DESCRIPTION("/MODULE_DESCRIPTION("optimized for emPC-A\/RPI3: /' sc16is7xx.c


        # SPI driver

        if [ $VERSION -ge 5 ]; then
                # Patch spi-bcm2835.c for Kernel 5.0.0+

                echo -e "$INFO INFO: patching spi-bcm2835.c with higher polling limit $NC" 1>&2
                patchfile spi-bcm2835.c "unsigned int polling_limit_us = 30;" "unsigned int polling_limit_us = 200;"

                echo -e "$INFO INFO: patching spi-bcm2835 with RT priority $NC" 1>&2
                insert2file spi-bcm2835.c "static int bcm2835_spi_probe" "ctlr->" "\tctlr->rt = 1;"
        else
                # Patch spi-bcm2835.c for Kernel 4.0.0+

                echo -e "$INFO INFO: patching spi-bcm2835.c with higher polling limit $NC" 1>&2
                patchfile spi-bcm2835.c "#define BCM2835_SPI_POLLING_LIMIT_US.*" "#define BCM2835_SPI_POLLING_LIMIT_US (200)"

                echo -e "$INFO INFO: patching spi-bcm2835 with RT priority $NC" 1>&2
                insert2file spi-bcm2835.c "static int bcm2835_spi_probe" "master->" "\tmaster->rt = 1;"
        fi


        # CAN driver
        echo -e "$INFO INFO: patching mcp251x.c to IRQF_TRIGGER_LOW | IRQF_ONESHOT $NC" 1>&2
        insert2file mcp251x.c "static int mcp251x_open" "threaded_irq" "\tflags = IRQF_TRIGGER_LOW | IRQF_ONESHOT;"

        echo -e "$INFO INFO: patching mcp251x.c with higher timeout to prevent can detection problems after soft-reboots $NC" 1>&2
        patchfile mcp251x.c "#define MCP251X_OST_DELAY_MS.*" "#define MCP251X_OST_DELAY_MS	(25)"


        # Serial driver
        if [ $VERSION -ge 5 ] && [ $PATCHLEVEL -ge 10 ]; then
                echo -e "$INFO INFO: patching sc16is7xx.c for kernel version 5.10+"
                patchfile sc16is7xx.c "sched_setscheduler(s->kworker_task, SCHED_FIFO, &sched_param);" "sched_set_fifo(s->kworker_task);"
        fi
	if [ $VERSION -ge 6 ] && [ $PATCHLEVEL -ge 1 ]; then
                echo -e "$INFO INFO: patching sc16is7xx.c for kernel version 6.1+"
                patchfile sc16is7xx.c "sched_setscheduler(s->kworker_task, SCHED_FIFO, &sched_param);" "sched_set_fifo(s->kworker_task);"
                patchfile sc16is7xx.c "struct ktermios \*old)" "const struct ktermios \*old)"
                patchfile sc16is7xx.c "static int sc16is7xx_config_rs485(struct uart_port \*port," "static int sc16is7xx_config_rs485(struct uart_port \*port, struct ktermios \*termios,"
                patchfile sc16is7xx.c "static int sc16is7xx_spi_remove(struct spi_device \*spi)" "static void sc16is7xx_spi_remove(struct spi_device \*spi)"
                patchfile sc16is7xx.c "return sc16is7xx_remove(\&spi->dev)\;" "sc16is7xx_remove(\&spi->dev)\;"
                patchfile sc16is7xx.c "static int sc16is7xx_i2c_remove(struct i2c_client \*client)" "static void sc16is7xx_i2c_remove(struct i2c_client \*client)"
                patchfile sc16is7xx.c "return sc16is7xx_remove(\&client->dev)\;" "sc16is7xx_remove(\&client->dev)\;"
        fi
fi


echo "obj-m += sc16is7xx.o" >Makefile
echo "obj-m += mcp251x.o" >>Makefile
echo "obj-m += spi-bcm2835.o" >>Makefile

echo "all:">>Makefile
echo -e "\tmake -C /lib/modules/$KERNEL/build M=/tmp/empc-arpi-linux-drivers modules" >>Makefile

make

if [ ! -f "mcp251x.ko" ] || [ ! -f "sc16is7xx.ko" ] || [ ! -f "spi-bcm2835.ko" ]; then
        echo -e "$ERR Error: Installation failed! (driver modules build failed) $NC" 1>&2
        whiptail --title "Error" --msgbox "Installation failed! (driver modules build failed)" 10 60
        exit 1
fi

# compile device tree files

wget -nv $REPORAW/src/mcp2515-can0-overlay.dts -O mcp2515-can0-overlay.dts
wget -nv $REPORAW/src/sc16is7xx-ttysc0-rs232-rs485-overlay.dts -O sc16is7xx-ttysc0-rs232-rs485-overlay.dts

wget -nv $REPORAW/src/mcp7940x-i2c-rtc-overlay.dts -O mcp7940x-i2c-rtc-overlay.dts

dtc -@ -H epapr -O dtb -W no-unit_address_vs_reg -o mcp2515-can0.dtbo -b 0 mcp2515-can0-overlay.dts
dtc -@ -H epapr -O dtb -W no-unit_address_vs_reg -o sc16is7xx-ttysc0-rs232-rs485.dtbo -b 0 sc16is7xx-ttysc0-rs232-rs485-overlay.dts

dtc -@ -H epapr -O dtb -W no-unit_address_vs_reg -o mcp7940x-i2c-rtc.dtbo -b 0 mcp7940x-i2c-rtc-overlay.dts

if [ ! -f "sc16is7xx-ttysc0-rs232-rs485.dtbo" ] || [ ! -f "mcp2515-can0.dtbo" ] || [ ! -f "mcp7940x-i2c-rtc.dtbo" ]; then
 echo -e "$ERR Error: Installation failed! (driver device tree build failed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (driver device tree build failed)" 10 60
 exit 1
fi

/bin/cp -rf mcp251x.ko /lib/modules/$KERNEL/kernel/drivers/net/can/spi/mcp251x.ko
/bin/cp -rf sc16is7xx.ko /lib/modules/$KERNEL/kernel/drivers/tty/serial/sc16is7xx.ko
/bin/cp -rf spi-bcm2835.ko /lib/modules/$KERNEL/kernel/drivers/spi/spi-bcm2835.ko

/bin/cp -rf mcp2515-can0.dtbo /boot/overlays/mcp2515-can0.dtbo
/bin/cp -rf sc16is7xx-ttysc0-rs232-rs485.dtbo /boot/overlays/sc16is7xx-ttysc0-rs232-rs485.dtbo
/bin/cp -rf mcp7940x-i2c-rtc.dtbo /boot/overlays/mcp7940x-i2c-rtc.dtbo

# register new driver modules
depmod -a

# update 2018-10 : check on every boot if J301 is set. if it is not set, then set RS485 mode automatically in driver using ioctl
wget -nv $REPORAW/src/tty-auto-rs485.c -O tty-auto-rs485.c
gcc tty-auto-rs485.c -o /usr/sbin/tty-auto-rs485

if [ ! -f "/usr/sbin/tty-auto-rs485" ]; then
        echo -e "$ERR Error: Installation failed! (could not build tty-auto-rs485) $NC" 1>&2
        whiptail --title "Error" --msgbox "Installation failed! (could not build tty-auto-rs485)" 10 60
        exit 1
fi

if grep -q "gpio24" "/etc/rc.local"; then
        echo ""
else
        echo -e "$INFO INFO: Installing RS232/RS485 jumper check in /etc/rc.local $NC"
        sed -i 's/exit 0//g' /etc/rc.local
        echo '# if jumper J301 is not set, switch /dev/ttySC0 to RS485 mode' >>/etc/rc.local
        echo '/bin/echo '"'"'24'"'"' > /sys/class/gpio/export || true; /bin/echo '"'"'in'"'"' > /sys/class/gpio/gpio24/direction && /bin/cat /sys/class/gpio/gpio24/value | /bin/grep '"'"'1'"'"' && /usr/sbin/tty-auto-rs485 /dev/ttySC0' >>/etc/rc.local
        echo "exit 0" >>/etc/rc.local
fi


WELCOME2="These configuration settings will automatically be made:\n
- Install default config.txt
- Install SocketCAN initialization as service
- Install RTC initialization in initramfs
- Increase USB max. current
- Enable I2C and SPI drivers
- Set green LED as SD card activity LED\n"

# emPC-A/RPI3B
cat /proc/cpuinfo | grep Revision | grep "082" >/dev/null
if (($? == 0)); then
        WELCOME2=$WELCOME2"- Disable Bluetooth (enable serial console)\n"
        WELCOME2=$WELCOME2"- Set CPU frequency to fixed 600MHZ\n"
fi

# emPC-A/RPI3B+
cat /proc/cpuinfo | grep Revision | grep "0d3" >/dev/null
if (($? == 0)); then
        WELCOME2=$WELCOME2"- Disable Bluetooth (enable serial console)\n"
        WELCOME2=$WELCOME2"- Set CPU frequency to fixed 600MHZ\n"
fi

WELCOME2=$WELCOME2"\ncontinue installation?"


if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "$WELCOME2" 18 60) then
        echo ""
else

        #update-alternatives --set gcc "/usr/bin/gcc-$GCCVERBACKUP"
        #update-alternatives --set g++ "/usr/bin/g++-$GCCVERBACKUP"

        exit 0
fi


DATE=$(date +"%Y%m%d_%H%M%S")
echo -e "$INFO INFO: creating backup copy of config: /boot/config-backup-$DATE.txt $NC" 1>&2
/bin/cp -rf /boot/config.txt /boot/config-backup-$DATE.txt

echo -e "$INFO INFO: Using default config.txt $NC" 1>&2
wget -nv $REPORAW/src/config.txt -O /boot/config.txt


# installing service to start can0 on boot
if [ ! -f "/bin/systemctl" ]; then
        echo -e "$ERR Warning: systemctl not found, cannot install can0.service $NC" 1>&2
else
        wget -nv $REPORAW/src/can0.service -O /lib/systemd/system/can0.service
        systemctl enable can0.service
fi



echo -e "$INFO INFO: Installing RTC hardware clock $NC" 1>&2
apt-get -y install i2c-tools
# disable fake clock (systemd)
systemctl disable fake-hwclock
systemctl mask fake-hwclock

# disable fake clock (init.d)
service fake-hwclock stop

rm -f /etc/cron.hourly/fake-hwclock
update-rc.d fake-hwclock disable

service hwclock.sh stop
update-rc.d hwclock.sh disable

if test -e /lib/systemd/system/hwclock.service; then
        # if exists from last installation (legacy, no longer used)
        echo -e "$INFO INFO: deinstalling hwclock.service $NC"
        systemctl stop hwclock || true
        systemctl disable hwclock || true
        systemctl mask hwclock || true
        rm -f /lib/systemd/system/hwclock.service
fi


echo -e "$INFO INFO: Disabling Bluetooth to use serial port $NC"
systemctl disable hciuart


if grep -q "ssh_host_dsa_key" "/etc/rc.local"; then
        echo ""
else
        echo -e "$INFO INFO: Installing SSH key generation /etc/rc.local $NC"
        sed -i 's/exit 0//g' /etc/rc.local
        echo "test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server" >>/etc/rc.local
        echo "exit 0" >>/etc/rc.local
fi



# read RTC time in initramfs (early as possible)
wget -nv $REPORAW/src/hwclock.hooks -O /etc/initramfs-tools/hooks/hwclock
wget -nv $REPORAW/src/hwclock.init-bottom -O /etc/initramfs-tools/scripts/init-bottom/hwclock

chmod +x /etc/initramfs-tools/hooks/hwclock
chmod +x /etc/initramfs-tools/scripts/init-bottom/hwclock

echo -e "$INFO INFO: generating initramfs $NC"
mkinitramfs -o /boot/initramfs.gz

if test -e /boot/initramfs.gz; then
	echo -e "$INFO INFO: Installing initramfs $NC"
	echo "initramfs initramfs.gz followkernel" >>/boot/config.txt
fi



wget -nv $REPORAW/scripts/empc-can-configbaudrate.sh -O /usr/sbin/empc-can-configbaudrate.sh
chmod +x /usr/sbin/empc-can-configbaudrate.sh
/usr/sbin/empc-can-configbaudrate.sh


if [ ! -f "/usr/local/bin/cansend" ]; then

        if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "Third party SocketCan library and utilities\n\n- libsocketcan-0.0.10\n- can-utils\n - candump\n - cansend\n - cangen\n\ninstall?" 16 60) then

                apt-get -y install git
                apt-get -y install autoconf
                apt-get -y install libtool

                cd /usr/src/

                wget http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.10.tar.bz2
                tar xvjf libsocketcan-0.0.10.tar.bz2
                rm -rf libsocketcan-0.0.10.tar.bz2
                cd libsocketcan-0.0.10
                ./configure && make -j4 && make install

                cd /usr/src/

                git clone https://github.com/linux-can/can-utils.git
                cd can-utils
                ./autogen.sh
                ./configure && make -j4 && make install

        fi
fi



if [ ! -f "/etc/CODESYSControl.cfg" ]; then
        echo ""
else
        echo -e "$INFO INFO: CODESYS installation found $NC"

        if (whiptail --title "CODESYS installation found" --yesno "CODESYS specific settings:\n- Set SYS_COMPORT1 to /dev/ttySC0\n- Install rts_set_baud.sh SocketCan script\n\ninstall?" 16 60) then

                wget -nv $REPORAW/src/codesys-settings.sh -O /tmp/codesys-settings.sh
                bash /tmp/codesys-settings.sh
fi
fi


if grep -q "sc16is7xx" "/etc/profile"; then
        echo ""
else
        echo -e "$INFO INFO: Installing driver installation check in /etc/profile $NC"
        echo "" >>/etc/profile
        echo "/sbin/lsmod | /bin/grep sc16is7xx >>/dev/null || /bin/echo -e \"\033[1;31mError:\033[0m driver for emPC-A/RPI RS232/RS485 port not loaded! installation instructions: https://github.com/janztec/empc-arpi-linux-drivers\"" >>/etc/profile
        echo "/sbin/lsmod | /bin/grep mcp251x >>/dev/null || /bin/echo -e \"\033[1;31mError:\033[0m driver for emPC-A/RPI CAN port not loaded! installation instructions: https://github.com/janztec/empc-arpi-linux-drivers\"" >>/etc/profile
        echo "/sbin/lsmod | /bin/grep rtc_ds1307 >>/dev/null || /bin/echo -e \"\033[1;31mError:\033[0m driver for emPC-A/RPI RTC not loaded! installation instructions: https://github.com/janztec/empc-arpi-linux-drivers\"" >>/etc/profile
fi


#update-alternatives --set gcc "/usr/bin/gcc-$GCCVERBACKUP"
#update-alternatives --set g++ "/usr/bin/g++-$GCCVERBACKUP"

cd /

if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "Installation completed! reboot required\n\nreboot now?" 12 60) then

        reboot
fi
