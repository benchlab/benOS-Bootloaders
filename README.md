<p align="center">
  <img src="https://github.com/benchlab/benchx-media/raw/master/benos-logo.png" width="300px" alt="benOS Logo"/>
</p> <br>

# benOS Bootloader

Bootloader for benOS Mercury. 

## Overview Of benOS Bootloader
The benOS bootloader goes through a strategic and a lightweight boot process whenever a computer or virual machine running benOS is powered on or restarted. Below, we will explain the process and how everything works from the ground up. 

A. `Bootloader` [ENTRY]
  1. `benstart` (benstart.asm)
  2. `benboot` (bootloader stage of benstart) is initialized via the primary partition of the device.

The benOS Bootloader is written in mostly Assembly and is built for x86_64 hardware. Currently we are working on an ARM-based integration but will probably never become compatible with i386-based computers. 
  
B. `benOS Microkernel` [KERNEL] < global benOS microkernel variable within the bootloader.
  1. `benkernel` (microkernel for benOS) is loaded at 0x10 initially and after db loads, 0x100000.
  2. `memoryMap` - Memory mapping boot stage (ben_mm.asm)
  3. `BenPlay` - BenPlay display boot stage (benplay.asm)

C. `benInit`
  1. `ramDiskInit` - At this boot stage, drivers, including drivers for the `benFS` (benOS Local File System) are loaded as     apart of the benOS microkernel image. Due to the way we load drivers at the `ramDiskInit` stage, it's an easy process when wanting to modify benOS, for loading different local filesystems, other than `benFS`, as the Administrative user. It is also just as easy to move benOS processes and/or drivers in/out of the `ramDisk`.
 
Example of how benOS loads `benFS` 
  
  ```text
  echo ############################
  echo ##   benOS is booting     ##
  echo ############################
  echo
  
  # Load the driver for the benFS Local Filesystem
  initfs:/bin/benfsd disk:/0
  
  # Launch the benFS filesystem
  cd file:/
  fsinit
  ```
  
  2. `benFS Loader` - benOS Local FileSystem is loaded 
  
D. `Login`
  1. benOS Server utilizes a terminal-first approach but can load the benOS GUI by simply typing 'x'
  2. benOS Desktop utilizes a GUI-first strategy and loads the GUI login screen immediately upon the finalization of the         benOS Bootloader. 
 
**Note:** ***`memoryMap` and `BenPlay` are loaded along with the kernel, because they heavily rely on functions within the benOS BIOS and it's a bit difficult to access them once the kernel has been loaded, so it is best to add them to the boot process at the same time we load the benOS microkernel.***

Using `interrupt` 0xFF, we load the benOS microkernel through an `interrupt table`. With benOS and our Assembly-based bootloader, the microkernel interrupt will only be available during the loading stages of `benOS bootloader`. Afterwards the benOS bootloader switches to the next stage `ben_mm` where the benOS microkernel duplicates the `memoryMap` via the `lowMemory`, initiates `pageMapping`, distributes the global ENV object and associated variables that are defined in the benOS microkernel. It takes the ENV object and then begins to initialize Bench Hardware-related drivers like `BenPlay` and schemes, directly into the benOS microkernel. It will also print out benOS microkernel information at this boot stage, like you can see below: 

```text
benOS 64 bits
 + PS/2
   + Keyboard
     - Reset FA, AA
     - Set defaults FA
     - Enable streaming FA
   + PS/2 Mouse
     - Reset FA, AA
     - Set defaults FA
     - Enable streaming FA
 + IDE on 0, 0, 0, 0, C120, IRQ: 0
   + Primary on: C120, 1F0, 3F4, IRQ E
     + Master: Status: 58 Serial: QM00001 Firmware: 2.0.0 Model: QEMUHARDDISK 48-bit LBA Size: 128 MB
     + Slave: Status: 0
   + Secondary on: C128, 170, 374, IRQ F
     + Master: Status: 41 Error: 2
     + Slave: Status: 0
 ```

## CREDITS AND ATTRIBUTES
This portion of benOS may use software from other open source libraries. For a full list of software credits and acknowledgements, please visit [https://github.com/benchlab/benOS/blob/master/ATTRIBUTES.md](https://github.com/benchlab/benOS/blob/master/ATTRIBUTES.md).
The original LICENSE or LICENSES for the originating software(s) and library or libraries that were used to create `benos-bootloader` are still active, although, considering this Bench software and the softwares and/or libraries/packages it is `imported` into may be used to issue illegal securities, the BENCH LICENSE is activated for this purpose. This does not take away the credits, disable the originating LICENSE or in any way disown the original creation, creators, developers or organizations that originally developed many of the libaries used throughout Bench's large array of software libraries packaged together for the purposes of building a decentralized operating system (benOS)

## VERSION
0.1.0

## LICENSE
BENCH LICENSE<br>
For benOS Bootloader
<br><br>
Copyright (c) 2018 Bench Computer, Inc. <legal@benchx.io>
<br><br>
Permission to use, copy, modify, and distribute this blockchain-related
software or blockchain-based software for any purpose with or without 
fee is hereby granted, provided that the above copyright notice and this 
permission notice appear in all copies.

THE USAGE OF THIS BLOCKCHAIN-RELATED OR BLOCKCHAIN-BASED SOFTWARE WITH THE
PURPOSE OF CREATING ICOS OR "INITIAL COIN OFFERINGS", UNREGISTERED SECURITIES 
SPECIFICALLY IN THE UNITED STATES OR IN OTHER COUNTRIES THAT HAVE A LEGAL 
FRAMEWORK FOR SECURITIES, IS PROHIBITED. BENCH FOUNDATION, LLC RESERVES THE 
RIGHT TO TAKE LEGAL ACTION AGAINST ANY AND ALL COMPANIES OR INDIVIDUALS WHO
USE THIS BLOCKCHAIN-RELATED OR BLOCKCHAIN-BASED SOFTWARE FOR THE PURPOSE OF 
DISTRIBUTING CRYPTOCURRENCIES WHERE THOSE CRYPTOCURRENCIES AND THEIR METHOD
OF DISTRIBUTION ARE IN DIRECT VIOLATION OF UNITED STATES SECURITIES LAWS. 
IF A GOVERNMENT BODY TAKES ACTION AGAINST ANY USERS, DEVELOPERS, MARKETERS,
ORGANIZATIONS, FOUNDATIONS OR ANY PROFESSIONAL ENTITY WHO CHOOSES TO UTILIZE
THIS SOFTWARE FOR THE DISTRIBUTION OF ILLEGAL SECURITIES, BENCH COMPUTER INC.
WILL NOT BE HELD LIABLE FOR ANY ACTIONS TAKEN BY THE USERS, DEVELOPERS, MARKETERS,
ORGANIZATIONS, FOUNDATIONS OR ANY PROFESSIONAL ENTITIES WHO CHOOSE TO DO SO.

UNITED STATES SECURITIES VIOLATIONS SPECIFICALLY REFER TO ANY VIOLATIONS OF
SECTION 10(b) OF THE SECURITIES EXCHANGE ACT OF 1934 [15 U.S.C. § 78j(b)] AND
RULE 10b-5(b) PROMULGATED THEREUNDER [17 C.F.R. § 240.10b-5(b)], AND
SECTIONS 5(a), 5(c), and 17(a)(2) OF THE SECURITIES ACT OF 1933 [15 U.S.C.
§§ 77e(a), 77e(c), and 77q(a)(2)]; BY MAKING USE OF ANY MEANS OR INSTRUMENTS
OF TRANSPORTATION OR COMMUNICATION IN INTERSTATE COMMERCE OR OF THE MAILS TO
SELL THROUGH THE USE OR MEDIUM OF ANY WRITTEN CONTRACT, OFFERING DOCUMENT,
PROSPECTUS, WHITEPAPER, OR OTHERWISE, ANY SECURITY AS TO WHICH NO REGISTRATION
STATEMENT WAS IN EFFECT. OR FOR THE PURPOSE OF SALE OR DELIVERY AFTER SALE,
CARRYING OR CAUSING TO BE CARRIED THROUGH THE MAILS OR IN INTERSTATE COMMERCE,
BY MEANS OR INSTRUMENTS OF TRANSPORTATION OR COMMUNICATION IN INTERSTATE
COMMERCE OR OF THE MAILS TO OFFER TO SELL OR OFFER TO BUY THROUGH THE USE OR 
MEDIUM OF ANY WRITTEN CONTRACT, OFFERING DOCUMENT, PROSPECTUS, WHITEPAPER,
OR OTHERWISE, SECURITIES AS TO WHICH NO REGISTRATION STATEMENT HAS BEEN FILED.

OUTSIDE OF THESE LEGAL REQUIREMENTS, THIS SOFTWARE IS PROVIDED "AS IS" AND 
THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING 
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL 
THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL 
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, 
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, 
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
