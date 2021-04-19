# emPC-A/RPI3, emPC-A/RPI3+, emVIEW-7/RPI3 & emVIEW-7/RPI3+ by Janz Tec AG 

This script installs and configures Linux **Socket CAN**, **Serial port RS232/RS485** and **RTC** drivers

## :large_orange_diamond: Installation Instructions

**:heavy_exclamation_mark:  recommended for new designs!**

In newer Raspbian images the Linux kernel is installed in version 4.9 (or later) and therefore our previous script _install.sh_ will no longer work correctly. For this newer Linux kernel versions, our new driver installation script _install.sh_ is still under development. Your feedback is welcome!

_create a backup copy of your µSD card before applying these steps!_

**Step 1:**

Install one of the listed RASPBIAN operating system versions from below: 

1) **Raspbian Stretch with desktop version 2018-11-13 or later**

   _install.sh_ script uses the mainline kernel driver sources with only a few source code patches, see _install.sh_ for more details. Our performance optimizations of the CAN, UART and SPI drivers are currently not included in these mainline drivers.   

   https://www.raspberrypi.org/downloads/raspbian/


**Step 2a:**


```
sudo bash
cd /tmp
wget https://raw.githubusercontent.com/janztec/empc-arpi3-linux-drivers/master/install.sh -O install.sh
bash install.sh
```


<br />
<br />
<br />


**Step 2b (Alternative if step 2a fails):**

Depending on the installed Linux kernel version it might be possible, that no matching kernel headers are available in the official Rasbian repository and step 2a fails. In this case it is possible to install the specific kernel version 20190819-1_armhf with matching kernel headers manually:

```
cd /tmp
sudo bash
wget https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel_1.20200601-1_armhf.deb
dpkg -i raspberrypi-kernel_1.20200601-1_armhf.deb
wget https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel-headers_1.20200601-1_armhf.deb
dpkg -i raspberrypi-kernel-headers_1.20200601-1_armhf.deb

reboot

sudo bash
cd /tmp
wget https://raw.githubusercontent.com/janztec/empc-arpi3-linux-drivers/master/install-withoutkernelheaderupdate.sh -O install-withoutkernelheaderupdate.sh
bash install-withoutkernelheaderupdate.sh
```

<br />
<br />
<br />

## Product pages
https://www.janztec.com/en/embedded-pc/embedded-computer/empc-arpi3/

**emPC-A/RPI3**

![emPC-A/RPI3](https://www.janztec.com/fileadmin/user_upload/Produkte/embedded/emPC-A-RPI2/janztec_produkte_embedded_emPC_RPI_raspberry_front.jpg)

**FEATURES emPC-A/RPI3**
* Processor 
  * Based on Raspberry Pi 3, Model B 
  * Broadcom BCM2837 processor 
  * Quad-Core CPU based on ARM Cortex-A53 
  * Fanless cooling concept 
  * Realtime clock, battery buffered 
* Memory 
  * System memory 1 GB 
  * External accessible ÂµSD card slot  
* Graphics 
  * HDMI graphic interface  
* Connectors  
  * 1 x 10/100 MBit/s Ethernet 
  * 4 x USB (v2.0) 
  * 1 x 9-pin D-SUB connector for serial debug console 
  * 1 x CAN (ISO/DIS 11989-2, opto-isolated, termination settings via jumper) 
  * 1 x RS232 (Rx, Tx, RTS, CTS) or switchable to RS485 (half duplex; termination settings via jumper)  
  * Internal I/O  
    * 4 x digital inputs (12 - 24VDC) 
    * 4 x digital outputs (12 - 24VDC)  
* Power Supply  
  * Input 9 â€¦ 32 VDC 
* DIN rail, wall mounting or desktop 

-------

**emVIEW-7/RPI3**

https://www.janztec.com/en/embedded-pc/panel-pc/emview-7rpi3/

![emVIEW-7/RPI3](https://www.janztec.com/fileadmin/user_upload/Produkte/embedded/emVIEW-7-RPI3/janz_tec_produkte_embedded_emVIEW-7_RPI3_front_schraeg_800x8001.jpg)

**FEATURES emVIEW-7/RPI3**
* LCD Display
   * 7.0" WSVGA display size
   * LED backlight technology
   * Resolution 800 x 480
   * Projected capacitive touch screen (PCAP) (with multitouch capabilities)
   * Glass surface
* Same I/O as emPC-A/RPI3


