+++
title = "A Tour Of ethflop"
description = "My experiences with using the new ethflop TSR for DOS- floppies over the network!"
date = 2019-12-11
aliases = ["blog/ethflop.html"]
+++

# A Tour Of ethflop
[ethflop](http://ethflop.sourceforge.net) is a new (2019!) [Terminate and Stay
Resident](https://en.wikipedia.org/wiki/Terminate_and_stay_resident_program)
(TSR) program for IBM PCs and compatibles running a DOS flavor. ethflop will
convert either your drive A:\\ or B:\\ floppy drive into a networked drive that
uses Ethernet frames to talk to a Linux server. The Linux server runs a daemon
called `ethflopd` that can supply floppy images in place of physical disks.

I first found out about ethflop from a [retweet](https://twitter.com/FreeDOS_Project/status/1199114211705675776)
of the FreeDOS Project's account. I knew then and there I _at least_ had
to try this out. It's like I was the target audience! And if you:

* Have old hardware "optimized" for running DOS.
* Enjoy (responsibly or otherwise!) networking your old computers to other old
  and new computers.
* Have a large number of floppy images that you downloaded over the years.

then I think ethflop is worth looking at! I imagine a number of
vintage-oriented people who would be happy with having access to a bunch of
floppy images from their DOS machine _without needing to write them to physical
floppies!_ So I've decided to take a look myself and write down my initial
experiences using ethflop.

## My Hardware Setup (For Testing)
ethflop requires two machines to use: a Linux server which runs a daemon
(`ethflopd`) that has access to some floppy images, and a machine running DOS
which interfaces to the Linux daemon to access said floppy images (using the
TSR portion of `ETHFLOP.COM`). I present the hardware setup I used in the next
two sections for <del>showing off my PC AT</del> <ins>giving the rest of this
post context</ins>. Feel free to [skip](#compiling-and-installing-ethflopd)
this section and refer back to it when necessary; it is mostly inessential.

### My 286 (DOS) Setup
My 286 is an early IBM PC AT running at 6 MHz. It has 2 floppy drives- drive A:\\
is a 1.2MB High Density drive, and drive B:\\ is a 360kB Double Density drive.
Additionally, my AT has one full height hard drive at drive C:\\
(the original [CMI](https://en.wikipedia.org/wiki/Computer_Memories_Inc.)
hard drive), and one half-height hard drive at D:\\ that sits rather snugly
in the slot under the 2 floppy drives. The C:\\ drive is the boot drive and the
D:\\ drive is used mainly for receiving temporary files that I subsequently
forget to clean up :).

{% figure(alt="Picture of my IBM PC AT", url="ctty.jpg") %}
Picture of my IBM PC AT, showing both floppy drives. The screen includes some
DOS commands I ran which are relevant to this blog post, including unloading
the <a href="https://shh.thathost.com/pub-dos/"><code>DOSED</code></a>
autocompleter (as it interferes with <code>CTTY</code>), loading a packet
driver, and then changing the console to a serial port via <code>CTTY</code>.
{% end %}

Because of <!-- [the way](#extra-how-ethflop-works) --> the way ethflop works, you lose access
to one of the floppy drives; I chose to use drive B:\\ with ethflop for testing
purposes. The hard drives are unaffected, and I've yet to test whether you can
reliably use ethflop with a boot floppy. _If you do not have a physical drive B:\\, you must use drive A:\\ with ethflop._
This is because DOS will emulate a virtual B:\\ drive using drive A:\\ if no
physical drive is detected, and no B:\\ drive requests will ever be sent to
ethflop.

My Network Interface Card (NIC) is a 3Com 3c509, which is still a fairly common
[ISA](https://en.wikipedia.org/wiki/Industry_Standard_Architecture) NIC that
can be even be found for sale off Ebay. 3Com still had packet drivers on their
website for the 3c509 when I was searching for them in late 2010, but they
pulled an Intel and they are long gone. Fortunately, the Internet Archive [comes through](http://web.archive.org/web/20060314185204/http://support.3com.com/infodeli/tools/nic/3c509.htm)
yet again!

Due to me misunderstanding the Ebay listing at the time, I bought a model of
3c509 which only has [thinnet (10BASE2)](https://en.wikipedia.org/wiki/10BASE2)
and [thicknet (10BASE5)](https://en.wikipedia.org/wiki/10BASE5) connections.
Fortunately, 10BASE2 to 10BASE-T converters are still common- if way too
expensive- and occassionally one can buy an old hub off Ebay with the same
hardware{{fn(id=1)}} as these converters. I'm not in a position to really
offer concrete advice on setting up 10BASE2 right now. The moral here is get
an ISA NIC with an RJ-45 connector, which is the [twisted pair (10BASE-T)](https://en.wikipedia.org/wiki/Ethernet_over_twisted_pair)
Ethernet that you know and love.

### Linux Setup
I used my headless [Tinker Board](https://www.asus.com/us/Single-Board-Computer/Tinker-Board/)
to run the Linux daemon. My distro is DietPi, though I imagine the distro
really doesn't matter; the source to `ethflopd` is contained in a single C file
and I had no troubles compiling and running it. Notably, I'm only using the
Tinker Board's wifi, and I can confirm _`ethflopd` will work if used with a
`wlan` interface._ I'm assuming my router takes care of converting from raw
Ethernet frames to 802.11 frames, because they are [not compatible](https://dot11ap.wordpress.com/ieee-802-11-frame-format-vs-ieee-802-3-frame-format/).

{% figure(alt="An SSH session with my Tinker Board.", url="linux-img.png") %}
This image shows a screen capture of an SSH session with the Tinker Board.
The listing shows I am in the floppy image directory and I have a few floppy
images prepared to share with the PC AT. I couldn't think of anything better to
show off a running headless system :).
{% end %}

For ease of testing, I am interfacing to DOS using a serial port and `minicom` on
the Tinker Board. It is possible to redirect DOS input and output to a serial
port (`COM2` in my case) using the `CTTY` command. Using `minicom` makes it
_much_ easier to capture DOS command output compared to taking photos. The
picture of my AT above was taken _just_ after I invoked `CTTY`.

## Compiling and Installing
Before using ethflop, one has to compile and install it first. I didn't have
any issues with compiling and installing, but I've documented my experiences
on how to do it for others just in case.

### Compiling and Installing `ethflopd`
To start, download the source distribution from the ethflop [website](http://ethflop.sourceforge.net)
using `wget` or other means. I recommend downloading the source to a Linux
machine. Once you unzip (`unzip -d ethflop ethflop-20191003.zip`) the source
distribution, you will see a directory like this:

```
wjones@DietPi:~/src/ethflop$ ls -l
total 120
-rw-r--r-- 1 wjones wjones 41865 Oct  3 16:48 ethflop.asm
-rw-r--r-- 1 wjones wjones  3696 Oct  3 17:04 ethflop.com
-rwxr-xr-x 1 wjones wjones 18568 Nov 25 22:15 ethflopd
-rw-r--r-- 1 wjones wjones 38305 Oct  3 16:50 ethflopd.c
-rw-r--r-- 1 wjones wjones  6192 Oct  3 16:55 ethflop.txt
-rw-r--r-- 1 wjones wjones   803 Oct  3 17:02 Makefile
```

The `ETHFLOP.COM` tsr is written in [`nasm`](https://nasm.us)-style assembly.
While `nasm` is provided by many Linux package repos, the author provided an
already-assembled `.COM` file for convenience. You will need to transfer this
file to your DOS machine.

The `ethflopd` portion of ethflop needs to be compiled manually. Type `make`
and you will get a binary at `ethflopd`. Any recent Linux should be able to run
`ethflopd`. As of this writing (12-8-2019), I have not tested the daemon on
non-Linux systems.

There's no install target, so you need to copy `ethflopd` to its final location
manually. In my case, I copied the file to my private bin directory:
`cp ethflopd ~/.local/bin`.

Lastly, create a storage directory for your floppy images: `mkdir ~/src/img`.
This is the directory `ethflopd` will use to present virtual floppy disks to
the DOS machine. Optionally, you can fill this directory with your floppy
images now :).

#### Optional Access Control
I recommend setting the [setuid](https://en.wikipedia.org/wiki/Setuid)
bit as well so you can execute the binary without needing sudo. Since this is
likely a private binary for your use alone, on a multiuser system (where you
have `sudo` privileges) you probably dont want others running `ethflopd`
either. I believe the following commands accomplish both:

1. Change the owner and group of `ethflopd` to `root` and your user's
  [primary group](https://unix.stackexchange.com/questions/410367/how-to-get-the-primary-group-of-a-user)
  respectively. As far as I know, the owner _must_ be root so `ethflopd` can
  create its runtime files and bind to an interface after `setuid` takes effect.
  On the other hand, the group is your primary group, so you can still run the
  executable.

   ```
   sudo chown root:wjones ~/.local/bin/ethflopd
   ```

2. Set the `setuid` bit on `ethflopd`. Make sure the group owner has executable
  permissions while the "others" group has the executable bit cleared. This
  ensures that only you or root can run `ethflopd` _if that's what you want._

   ```
   sudo chmod 4754 ~/.local/bin/ethflopd
   ```

### Installing `ETHFLOP.COM`
At a minimum, you will need to transfer `ETHFLOP.COM` and a packet driver for
your particular NIC to your retro machine. If you can't find a packet driver
for your card easily, [tweet](https://twitter.com/cr1901) or
[email](mailto://thor0505@comcast.net) me and I'll see if I can help. I don't
have a _large_ collection of packet drivers myself (CNET, Kingston, 3Com), but
I can point you in the right direction.{{fn(id=2)}}

Once you have `ETHFLOP.COM` and a packet driver on your retro machine, you're
good to go! There is no special installation required; `ETHFLOP.COM` is
self-contained. It's probably a good idea to make sure `ETHFLOP.COM` and your
packet driver can be seen by the DOS `PATH` though.

Of course, one has to actually _get_ `ETHFLOP.COM` from the distribution you
unzipped on your Linux machine to the vintage machine in order to actually
_use_ ethflop to its full potential. About that...

#### _Transferring_ `ETHFLOP.COM` To The Target Machine
Unfortunately, _getting_ files from a modern machine to a retro DOS machine is
quite a topic in and of itself. There's various ways to do this- serial port,
floppy, over the network, cdrom attached to the parallel port, zip disks, etc.
Depending on how much extra hardware you have, transferring a file from a new
to old machine ranges from fun to very tedious.

##### My Preferred Transfer Method- TCP/IP!
It was fun for me personally to transfer `ETHFLOP.COM` to an old machine
because I had set up TCP/IP on my my PC AT years ago using [mTCP](http://www.brutman.com/mTCP/).
mTCP applications integrate the TCP/IP stack into their binaries. The main
distribution provides an FTP client (`FTP`) and HTTP downloader (`HTGET`),
among other useful programs. I have also written [my own](https://github.com/cr1901/nwbackup)
software using mTCP.

For transferring files from a new to old machine, I normally prefer using the
`FTP` client, but recently, I've had trouble setting up a temporary working
FTP server using [`pyftpdlib`](https://github.com/giampaolo/pyftpdlib).
Specifically, the server claims to transfer the file, but mTCP `FTP` terminates
the transfer immediately. Instead I decided to use `python3`'s `http.server`
module and then download the file to my AT using `HTGET`. Specifically:

1. On the Linux/modern side, invoke an HTTP server in the ethflop directory:

   ```
   wjones@DietPi:~/src/ethflop$ python3 -m http.server
   Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
   ```

2. On the DOS/retro side, connect to the newly-invoked HTTP server and
   download `ETHFLOP.COM` using `HTGET`:

   ```
   HTGET -o ETHFLOP.COM 192.168.1.162:8000/ethflop.com
   ```

In less than a second, I had `ETHFLOP.COM` safely on my AT! The power of TCP/IP
and Ethernet still amazes me.

I don't remember the exact details of how I got mTCP onto my AT initially, but
as I recall I had to use a third computer with a zip drive and 5.25" floppy
drive as an intermediate. I used a USB Zip drive to copy files from my laptop.
The files were read by the intermediate computer's _internal_ Zip drive, and
then copied onto the intermediate's 5.25" 1.2MB drive, which I then could write
onto the AT's hard disk.

##### Bootstrapping
**I apologize in advance for the length of this section. This needs to be spun
off into a blog post by itself. Feel free to [skip](#usage) to the next
section.**

In the absence of a working network connection, I understand using floppy disks
for data transfer to old systems is sometimes not an option. While a floppy
drive is pretty much the lowest common denominator of hardware
for IBM PCs, clones, and descendants, I've seen a few issues:

* Getting blank 5.25" floppies is inconvenient in 2019.
* Even after you get a 5.25" drive for a second machine, I don't think any of
  the modern USB 5.25" floppy drive interfaces support writing disks
  (no demand?). So you need to setup up an intermediate machine as I described
  in the previous section.
* Occassionally, I've seen people with broken floppy drives who want to install
  software onto their machine.

I think serial port is the method for transferring data between new and old
machines that makes the _least_ amount of assumptions about available hardware.
A serial port in [DB-9 or DB-25](https://en.wikipedia.org/wiki/D-subminiature)
form factor is pretty a common hardware addition to even the oldest IBM PC and
clones. Serial ports are traditionally accessed through the DOS command line by
the special names `COM[1-4]` or `AUX` (for COMmmunications or AUXilary). Modern
OSes have good support for DB-9 serial ports via [USB adapters](https://www.adafruit.com/product/18)
or [PCI Express](https://www.asix.com.tw/products.php?op=pItemdetail&PItemID=122;74;110&PLine=74)
because RS-232 is still widely used for better or worse. You will need a [null-modem](https://en.wikipedia.org/wiki/Null_modem)
cable or adapter to connect your modern and retro computer together; these are
still widely available to purchase.

There are a few [bootstrap](https://retrocomputing.stackexchange.com/a/9762)
mechanisms that have been developed over the years for DOS. They mostly involve
typing in scripts (like BASIC) and/or small exectuables whose [opcodes](ftp://kermit.columbia.edu/kermit/a/tcomtxt.asm)
or [encoding](http://www.columbia.edu/kermit/archive.html#boofile) only use
ASCII characters. Because the bootstraps only create files with ASCII
characters, one can use the DOS `COPY`command to read bootstrap programs from
the serial port, such as `COPY COM1 XFER.COM`. The ASCII restriction is because
DOS uses the `EOF` ASCII character (`^Z`) to know when the transfer is
finished.{{fn(id=3)}}

Bootstrap programs often implement a minimal [Kermit protocol](http://www.columbia.edu/kermit/kermit.html)
receiver program. Unlike the DOS `COPY` command, the Kermit protocol can send
and receive files with arbitrary bytes, and the protocol was designed to be
extremely portable to new machines. The Kermit Project took the bootstrap
problem of "transferring the file-transfer program to a new computer"
seriously; all the bootstrap links I provided in this section are part of the
Kermit archive at Columbia.

I use either `minicom` or [Tera Term](https://ttssh2.osdn.jp/index.html.en) as
my serial transfer programs on machines with modern OSes. Both of these
programs understand the Kermit protocol _and_ can be used to send a file down
the serial line as-is for the DOS `COPY` command. However, _you must manually
send the `EOF` (`^Z`) control character yourself afterwards in both programs._

I can vouch personally that [`msbrcv.bas`](ftp://kermit.columbia.edu/kermit/a/msbrcv.bas)
has worked for me in the past with `QBASIC`. I have not tested in older DOS
versions using `BASIC` or `BASICA` as of this writing (12-8-2017). I plan to
test transfers with [`TCOM.COM`](ftp://kermit.columbia.edu/kermit/a/tcomtxt.asm)
in the near future, which may be preferable since it doesn't require BASIC.
Really, I should probably write a blog post on bootstrapping and move this
whole section there :).

## Usage
### Starting and Stopping `ethflopd`
To start the daemon, supply the following command line arguments in order:

1. The network interface you wish to listen on (`eth0`, `wlan0`- _wireless interfaces work_, etc.) .
2. The storage directory of your floppy images.

My invocation looks like: `ethflopd wlan0 ~/src/img/`. There is an optional
`-f` option to run the daemon in the foreground as well. I find this useful if
you wish to invoke `ethflopd` for as long as you're running your DOS machine,
as opposed to running `ethflopd` continuously.

Once `ethflopd` is running, it will listen for the [MAC address](https://en.wikipedia.org/wiki/MAC_address)
of a networked DOS computer running `ETHFLOP.COM` to send and receive virtual
floppy images. From the DOS side, detecting the MAC address of a machine
running `ethflopd` is automatic. To reiterate, there is no IP address setup
because ethflop uses raw Ethernet/Wifi frames to transfer data.

To stop the daemon, you need to `kill` the PID associated with `ethflopd` or
run `pkill ethflopd`. `sudo` may be required depending on your particular
setup. If `ethflop` is running in the foreground, `^C` works fine as
well :); `ethflopd` has the same cleanup code for both `kill` and `^C`.

### A Guided Tour Of `ETHFLOP.COM`
Once the daemon is running on the Linux machine, the first thing to do on the
DOS end is... read the help text :). I have copied the output of running
ethflop without any arguments for your convenience!

```
C:\>ethflop
ethflop v0.6 - a floppy drive emulator over Ethernet
Copyright (C) 2019 Mateusz Viste

=== USAGE ====================================================================
ethflop a           installs the ethflop TSR as A:
ethflop b           installs ethflop as B: (works only if you have a real B:)
ethflop i DISKNAME  'inserts' the virtual floppy named 'DISKNAME'
ethflop ip DSKNAME  same as 'i', but the inserted floppy is WRITE PROTECTED
ethflop r OLD NEW   renames virt. floppy 'OLD' to 'NEW'
ethflop e           'ejects' currently loaded virtual floppy
ethflop nSZ DSKNAME creates a new virt. floppy DSKNAME, SZ KB big. SZ can be:
                    360, 720, 1200, 1440, 2880, 4800, 8100, 9600, 15500, 31000
ethflop l           displays the list of available virt. floppies
ethflop d DISKNAME  DELETES virt. floppy named DISKNAME - BE CAREFUL!
ethflop s           displays current status of the ethflop TSR
ethflop u           unloads the ethflop TSR

=== NOTES ====================================================================
 * Disk names must be 1 to 8 characters long. Only A-Z, 0-9 and '_-' allowed.
 * ethflop requires the presence of an ethflop server on the local network.

=== LICENSE ==================================================================
ethflop is published under the terms of the ISC license. See ETHFLOP.TXT.
```

ethflop can basically be divided into three command types:
* Load/unload TSR (`a`, `b`, `u`)
* Query commands (`l`, `s`)
* Operate on virtual disks (`i`, `ip`, `r`, `e`, `n`, `d`)

#### Loading/Unloading the TSR
##### Packet Driver Installation
The <del>first</del> <ins>second</ins> thing to do is to make sure your packet
driver is loaded into memory. In my case with the 3c509, this looks like:

```
C:\>3c5x9pd 0x60

3Com EtherLink 10 ISA Packet Driver v1.2
(C) Copyright 1993 3Com Corp.  All rights reserved.
Error: The interrupt requested is already in use by another packet driver.
```

The lone argument to `3C5X9PD.COM` is the x86 interrupt number to use to
call into the packet driver. Interrupt `0x60` is a good traditional default, as
indicated by the error message telling me I already loaded the driver.

Some packet drivers require more options to set up, but chances are the
default options provided in your NIC manual or by the supplied configuration
program- as is the case with the 3c509- will work correctly. Older machines may
require a bit more fine tuning, but between three different NIC manufactuters
over a dozen DOS machines, I've had the default options not work exactly
once{{fn(id=4)}}. Manually assigning resources becomes more important if you
have multiple NICs installed in a retro machine, but this is rare.

##### TSR Installation
After you're sure a packet driver is loaded, then it's time to load the TSR! As
I said before, if you only have a single physical floppy drive, you must use
`ethflop a`. However, seeing as I _do_ have a physical B:\\ drive, I installed
ethflop at drive B:\\:

```
C:\>ethflop b
server found at F0:03:8C:90:B2:A1
current virt. floppy: <NONE>
ethflop has been installed
```

`ETHFLOP.COM` will attempt to [automatically find](https://en.wikipedia.org/wiki/Broadcast_address#Ethernet)
a server running `ethflopd`  without user invervention. It _can_ take multiple
tries to load the driver depending on your network connection quality. However,
I've found that once `ETHFLOP.COM` _finds_ the server, any subsequent network
errors are transient and the TSR keeps working.

Once ethflop is installed, you lose access to the underlying physical drive.
_This also means that you can't use ethflop if you don't have a physical floppy
drive._{{fn(id=5)}} The virtual floppy drive presented by ethflop will be
empty; you must either load or create a virtual disk before accessing the
drive, or else you will get DOS' famous error message:

```
C:\>B:


Seek error reading drive B
Abort, Retry, Fail?f
Current drive is no longer valid>C:

C:\>
```

I have not tested whether ethflop can coexist with applications using a DOS
TCP/IP stack, though I can't see any immediate problems.

##### Unloading `ETHFLOP.COM`
When you're done playing with virtual floppies and/or need to access the
physical drive, type `ethflop u` to uninstall the TSR:

```
C:\>ethflop u
ethflop has been uninstalled
```

You will get access back to your underlying physical floppy drive as well as
the NIC after unloading.

#### Querying commands
You can get information about the ethflop TSR and what disks are available by
running `ethflop s` and `ethflop l` respectively:

```
C:\>ethflop s
ethflop is currently installed as drive B:
server is at F0:03:8C:90:B2:A1
current virt. floppy: <NONE>
C:\>ethflop l
 msdos213    mydisk
```

Uh oh, one of my virtual disks is missing from the list! As it turns out, _the
file extension for your images matter_! I've been sloppy about this in the
past, switching between `.ima` or `.img` on a whim. Renaming `mtcpget.ima` to
`mtcpget.img` in my image directory on the Tinker Board makes all three images
appear during a query:

```
C:\>ethflop l
 msdos213   mtcpget    mydisk
```

Much better!

#### Using Virtual Disks
Commands to operate on virtual disks are the bulk of `ETHFLOP.COM`'s
functionality. Any typical action you would perform on a physical floppy disk
has an equivalent coded into `ETHFLOP.COM`:

* `i`- Insert a virtual disk (place a disk into the disk drive).
* `e`- Eject a virtual disk (remove the disk from the disk drive).
* `ip`- Write-protect and insert a virtual disk (cover a notch or slide a
   switch on the disk, then insert).
* `r`- Rename a virtual disk (change the label on the sleeve/cover).
* `n`- Create a new virtual disk (go to the store and buy some floppies).
* `d`- Delete a virutal disk (erase a good floppy or discard a bad floppy).

I present these commands in the order I tried them out in my initial ETHFLOP
session, which matches the list above.

##### Insert
Let's insert a disk! I chose `mtcpget` because I actually forgot the contents
of this image and wanted to see what I used it for. Listing the root directory
using `DIR` works without a hitch:

```
C:\>ethflop i mtcpget
Disk MTCPGET loaded (360 KiB)
C:\>B:

B:\>dir

 Volume in drive B has no label
 Volume Serial Number is AEA9-1EC3
 Directory of B:\

MTCPGET  BAT       870 01-01-80   3:34p
PKT_DRVS     <DIR>     05-16-12   1:52p
UTILS        <DIR>     05-16-12   1:53p
CFG          <DIR>     05-16-12   1:53p
BATCH        <DIR>     05-16-12   2:15p
GO       BAT         0 05-16-12   2:15p
        6 file(s)        870 bytes
                      101376 bytes free

B:\>
```

Looks like I used this disk to bootstrap mTCP onto new machines. Displaying
the contents of the `MTCPGET.BAT` file using `TYPE` confirms this. Good to
know that accessing files works fine as well.

```
B:\>type MTCPGET.BAT
REM ECHO OFF
ECHO This batch file retrieves the mTCP stack and programs using mTCP FTP.
ECHO Make sure environment is unset and batch variables are set correctly before using this file.
ECHO In addition, make sure the packet driver is functional.
PAUSE

SET SRCDRIV=A:
SET PATH=%SRCDRIV%\UTILS
SET DESTDRIV=C:
SET MACHINE=8088
SET MTCPCFG=%SRCDRIV%\CFG\BATCHTCP.CFG
SET SERVER=192.168.1.3

ECHO Switching to destination drive...
%DESTDRIV%

ECHO Obtaining DHCP configuration...
DHCP

ECHO Obtaining mTCP stack/programs...
FTP %SERVER% < %SRCDRIV%\CFG\MTCP.FTP

ECHO Obtaining machine-specific files...
FTP %SERVER% < %SRCDRIV%\CFG\%MACHINE%.FTP

ECHO Switching back to source drive...
%SRCDRIV%

ECHO This batch file has completed executing.
ECHO It is recommended to restart the computer at this time to restore the environment.
PAUSE
```

##### Eject
I didn't have much to do with `MTCPGET`, so I soon ejected this disk. I tested
that this worked by deliberately accessing a non-existent disk. I am curious
that [`f`ailing](https://en.wikipedia.org/wiki/Abort,_Retry,_Fail%3F#Description)
on the first error successfully read out a blank volume label, but even with
that behavior, the eject command works fine to me:

```
B:\>ethflop e
Disk MTCPGET ejected
B:\>dir


Seek error reading drive B
Abort, Retry, Fail?f
Volume in drive B has no label

Seek error reading drive B
Abort, Retry, Fail?f

Not ready reading drive B
Abort, Retry, Fail?f
Fail on INT 24


Seek error reading drive B
Abort, Retry, Fail?f
Current drive is no longer valid>C:
```

##### Write Protect, Then Insert
Because I live life on the edge, I decided to test whether write-protect works
on one of my pristine, old MS-DOS images. If this fails, then I've lost...
pretty much nothing, because this is a backup copy of the image :). I don't
know why the volume label is missing 3 hex digits- I will investigate and
update later.

```
C:\>ethflop ip msdos213
Disk MSDOS213 loaded (360 KiB (write-protected))
C:\>B:

B:\>mkdir FOO

Write protect error writing drive B
Abort, Retry, Fail?f
Fail on INT 24 - FOO

B:\>dir

 Volume in drive B is E107-A
 Directory of B:\

BIN          <DIR>     08-27-11  12:51p
COMMAND  COM     16421 07-16-84   9:50a
ALTCHAR  SYS       431 04-04-84   8:22a
AUTOEXEC BAT        23 04-04-84   8:11a
        4 file(s)      16875 bytes
                       75776 bytes free

B:\>
```

Since write-protected succeeded according to the error, it looks like I saved
myself an extra `rsync`/`cp` command to reset my MS-DOS image. And based on
the modification date of `BIN`, this image isn't pristine/original at all!
Ah well...

##### Rename
Renaming a virtual disk has interesting behavior- the rename operation appears
to be case insensitive, even on the Linux side! I expected the image filename
on the server to be renamed with the same case that I typed it at the DOS
prompt:

```
B:\>ethflop r mydisk MYDBAK
Disk MYDISK renamed to MYDBAK
```

However, it looks like either `ethflopd` or `ETHFLOP.COM` sanitizes the image
name so that only lowercase image filenames are created on the server side:
```
wjones@DietPi:~/src/img$ ls
msdos213.img  mtcpget.img  mydbak.img
```

I did not try renaming a virtual disk that's inserted. I will update this
post in the future with the behavior when I have time to test.

`MYDISK` was an image I had created in a prior ethflop session. I renamed it to
`MYDBAK` (`BAK` as in "backup") because I want to duplicate the process of
creating `MYDISK` with a fresh new image *for reasons I will describe in the
next section*. Speaking of which...

##### Create An Image
The most powerful feature of ethflop in my opinion is the ability to create
new virtual disks to store on the server. Compared to copying floppies,
creating and populating a virtual disk is much more convenient to quickly share
a new disk with your other networked computers. You can even store your shiny
new image image on an FTP server or BBS (those things still exist, right?) to
share with other like-minded retro-enthusiasts in record time!

To create an image, use the `n` command and supply a size and disk name as
arguments:

```
B:\>ethflop n360 mydisk
Disk MYDISK created (360 KiB)
```

Listing the image directory contents shows that I indeed create a new floppy
image. Note that the image owner and group match those of the user invoking
`ethflopd` (after `setuid` takes effect). The permissions of `mydbak.img` in
the listing were from a previous `ethflopd` session using `sudo`:

```
wjones@DietPi:~/src/img$ ls -l
total 848
-rw-r--r-- 1 wjones wjones 368640 Sep 22  2012 msdos213.img
-rw-r--r-- 1 wjones wjones 368640 May 16  2012 mtcpget.img
-rw-r--r-- 1 root   root   368640 Dec  4 13:53 mydbak.img
-rw-r--r-- 1 root   wjones 368640 Dec  5 13:19 mydisk.img
```

After creating an image, you need to insert your shiny new disk before using
it. Based on the `Seek error` messages, I was having network trouble at the
time. However, I _did_ eventually manage to connect to the server:

```
B:\>ethflop i mydisk
ERROR: you must first eject your current virtual floppy (MSDOS213)
B:\>ethflop e
Disk MSDOS213 ejected
B:\>ethflop i mydisk

Seek error reading drive B
Abort, Retry, Fail?r

Seek error reading drive B
Abort, Retry, Fail?r

Seek error reading drive B
Abort, Retry, Fail?r

Seek error reading drive B
Abort, Retry, Fail?f
Invalid drive specification
Disk MYDISK loaded (360 KiB)
B:\>dir

 Volume in drive B has no label
 Volume Serial Number is 5DE9-4A1E
 Directory of B:\

File not found

B:\>
```

Once `ETHFLOP.COM` connected to the server, I didn't have any further trouble.

On a lark, I decided to try to recreate my existing `MYDBAK` virtual disk,
including the `TEST` directory and `TEST.TXT` file. I was curious what bytes,
if any, would be different between the two images beyond timestamps.
Unfortunately, I made a mistake and accidentally quoted the contents of
`TEST.TXT`. My mistake will come up [again](#unexpected-directory-entries) a
bit later.

```
B:\>mkdir TEST

Not ready writing drive B
Abort, Retry, Fail?r

B:\>cd TEST

B:\TEST>echo "This is a test file" > TEST.TXT

B:\TEST>ethflop e
Disk MYDISK ejected
```

###### Unsupported Hardware Floppy Density Emulation
You can even create images of floppy densities that the hardware doesn't
support! In the below snippet, I create a 1.44MB 3.5" virtual disk and populate
it much the same way as the previous examples, minus the quotes this time :):

```
C:\>ethflop n1440 hddisk
Disk HDDISK created (1440 KiB)
C:\>ethflop i hddisk
Disk HDDISK loaded (1440 KiB)
C:\>B:

B:\>mkdir TEST

B:\>dir

 Volume in drive B has no label
 Volume Serial Number is 5DE9-4BEB
 Directory of B:\

TEST         <DIR>     12-05-19   1:27p
        1 file(s)          0 bytes
                     1457152 bytes free

B:\TEST>echo This is a test file > TEST.TXT

B:\TEST>type TEST.TXT
This is a test file

B:\TEST>ethflop e
Disk HDDISK ejected
```

By doing a hexdump on the server (`alias hd='od -Ax -t x1z'`), you can see the
image indeed is the size of a 1.44MB disk, and includes the file I just created
starting at `004400`. File metadata- known in FAT file system terms as the
[directory entry](https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Directory_entry)-
is also visible starting at `004240`:

```
wjones@DietPi:~/src/img$ hd hddisk.img
000000 eb fe 90 4d 53 44 4f 53 35 2e 30 00 02 01 01 00  >...MSDOS5.0.....<
000010 02 e0 00 40 0b f0 09 00 12 00 02 00 00 00 00 00  >...@............<
000020 00 00 00 00 00 00 29 eb 4b e9 5d 4e 4f 20 4e 41  >......).K.]NO NA<
000030 4d 45 20 20 20 20 46 41 54 31 32 20 20 20 00 00  >ME    FAT12   ..<
000040 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
0001f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 aa  >..............U.<
000200 f0 ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000210 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001400 f0 ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
001410 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
002600 54 45 53 54 20 20 20 20 20 20 20 10 00 00 00 00  >TEST       .....<
002610 00 00 00 00 00 00 62 6b 85 4f 02 00 00 00 00 00  >......bk.O......<
002620 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
004200 2e 20 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >.          .....<
004210 00 00 00 00 00 00 62 6b 85 4f 02 00 00 00 00 00  >......bk.O......<
004220 2e 2e 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >..         .....<
004230 00 00 00 00 00 00 62 6b 85 4f 00 00 00 00 00 00  >......bk.O......<
004240 54 45 53 54 20 20 20 20 54 58 54 20 00 00 00 00  >TEST    TXT ....<
004250 00 00 00 00 00 00 aa 6b 85 4f 03 00 16 00 00 00  >.......k.O......<
004260 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
004400 54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 66  >This is a test f<
004410 69 6c 65 20 0d 0a 00 60 a9 16 eb 00 02 2f 00 00  >ile ...`...../..<
004420 46 44 49 53 4b 20 20 20 43 4f 4d 00 00 00 00 00  >FDISK   COM.....<
004430 00 00 00 00 00 00 00 60 a9 16 f1 00 d8 df 00 00  >.......`........<
004440 46 4f 52 4d 41 54 20 20 43 4f 4d 00 00 00 00 00  >FORMAT  COM.....<
004450 00 00 00 00 00 00 00 60 a9 16 0d 01 8f 80 00 00  >.......`........<
004460 4d 49 52 52 4f 52 20 20 43 4f 4d 00 00 00 00 00  >MIRROR  COM.....<
004470 00 00 00 00 00 00 00 60 a9 16 1e 01 f9 46 00 00  >.......`.....F..<
004480 33 43 35 58 39 50 44 20 43 4f 4d 00 00 00 00 00  >3C5X9PD COM.....<
004490 00 00 00 00 00 00 ac 80 85 26 89 13 bc 31 00 00  >.........&...1..<
0044a0 53 48 41 52 45 20 20 20 45 58 45 00 00 00 00 00  >SHARE   EXE.....<
0044b0 00 00 00 00 00 00 00 60 a9 16 2a 01 90 2a 00 00  >.......`..*..*..<
0044c0 53 4d 41 52 54 44 52 56 53 59 53 00 00 00 00 00  >SMARTDRVSYS.....<
0044d0 00 00 00 00 00 00 00 60 a9 16 30 01 83 20 00 00  >.......`..0.. ..<
0044e0 53 59 53 20 20 20 20 20 43 4f 4d 00 00 00 00 00  >SYS     COM.....<
0044f0 00 00 00 00 00 00 00 60 a9 16 35 01 70 34 00 00  >.......`..5.p4..<
004500 55 4e 44 45 4c 45 54 45 45 58 45 00 00 00 00 00  >UNDELETEEXE.....<
004510 00 00 00 00 00 00 00 60 a9 16 3c 01 64 36 00 00  >.......`..<.d6..<
004520 55 4e 46 4f 52 4d 41 54 43 4f 4d 00 00 00 00 00  >UNFORMATCOM.....<
004530 00 00 00 00 00 00 00 60 a9 16 43 01 90 48 00 00  >.......`..C..H..<
004540 58 43 4f 50 59 20 20 20 45 58 45 00 00 00 00 00  >XCOPY   EXE.....<
004550 00 00 00 00 00 00 00 60 a9 16 4d 01 bc 3d 00 00  >.......`..M..=..<
004560 44 4f 53 4b 45 59 20 20 43 4f 4d 00 00 00 00 00  >DOSKEY  COM.....<
004570 00 00 00 00 00 00 00 60 a9 16 55 01 fc 16 00 00  >.......`..U.....<
004580 44 4f 53 53 48 45 4c 4c 56 49 44 00 00 00 00 00  >DOSSHELLVID.....<
004590 00 00 00 00 00 00 00 60 a9 16 58 01 f6 24 00 00  >.......`..X..$..<
0045a0 54 43 50 20 20 20 20 20 20 20 20 10 00 00 00 00  >TCP        .....<
0045b0 00 00 00 00 00 00 ee 10 24 c8 aa 04 00 00 00 00  >........$.......<
0045c0 44 4f 53 53 48 45 4c 4c 43 4f 4d 00 00 00 00 00  >DOSSHELLCOM.....<
0045d0 00 00 00 00 00 00 00 60 a9 16 63 01 02 12 00 00  >.......`..c.....<
0045e0 44 4f 53 53 48 45 4c 4c 45 58 45 00 00 00 00 00  >DOSSHELLEXE.....<
0045f0 00 00 00 00 00 00 00 60 a9 16 66 01 0e 98 03 00  >.......`..f.....<
004600 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
168000
```

I assume the density of floppy images you can create and write depends
on the DOS version you're running. My 286 runs PC-DOS 5.0, which supports
1.44MB disks just fine, but I know my 286 BIOS does _not_ support 1.44MB
disks. I don't know at present how `ETHFLOP.COM` interacts with the BIOS
bookkeeping, if at all. **Until I know for sure, I am using this feature with
caution.**

In the above dump of `hddisk.img`, the data starting at `FDISK` and beyond
appear to be legitimate directory entries from my AT's hard disk. _I am not
sure why `ethflopd` is creating these entries._ My guess is this behavior isn't
intentional, as none of these directory entries are actually reachable; bytes
`002620` and `004260` would need to be [nonzero](https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Directory_entry)
to indicate more files are present in either the root or `TEST` directories.

Seeing as I'm not storing sensitive data on my AT, I'm not exactly worried
about extra data being copied to my newly-created virtual disks. However, I
found the behavior strange enough to be worth noting. If you're a retro
enthusiast who stores sensitive data on their retro machines (_I'm_ not gonna
judge you), I would check to make sure newly-created virtual images don't
accidentally copy sensitive data to the server. In the meantime, I'll look
further into this behavior.

###### Unexpected Directory Entries
What follows is my attempts to flesh out why extra directory entries are
created. If you don't feel like looking at hexdumps, [skip](#delete) to the
next section!

The extra directory entries seem to disappear when I _recreate_ an existing
image. For example, my second (_and still wrong_) attempt to duplicate `mydbak.img`
from a fresh copy of `mydisk.img` resulted in the following hexdumps:

```
wjones@DietPi:~/src/img$ hd mydisk.img
000000 eb fe 90 4d 53 44 4f 53 35 2e 30 00 02 02 01 00  >...MSDOS5.0.....<
000010 02 70 00 d0 02 fd 02 00 09 00 02 00 00 00 00 00  >.p..............<
000020 00 00 00 00 00 00 29 1e 4a e9 5d 4e 4f 20 4e 41  >......).J.]NO NA<
000030 4d 45 20 20 20 20 46 41 54 31 32 20 20 20 00 00  >ME    FAT12   ..<
000040 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
0001f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 aa  >..............U.<
000200 fd ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000210 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
000600 fd ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000610 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
000a00 54 45 53 54 20 20 20 20 20 20 20 10 00 00 00 00  >TEST       .....<
000a10 00 00 00 00 00 00 b7 6a 85 4f 02 00 00 00 00 00  >.......j.O......<
000a20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001800 2e 20 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >.          .....<
001810 00 00 00 00 00 00 b7 6a 85 4f 02 00 00 00 00 00  >.......j.O......<
001820 2e 2e 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >..         .....<
001830 00 00 00 00 00 00 b7 6a 85 4f 00 00 00 00 00 00  >.......j.O......<
001840 54 45 53 54 20 20 20 20 54 58 54 20 00 00 00 00  >TEST    TXT ....<
001850 00 00 00 00 00 00 c9 6a 85 4f 03 00 18 00 00 00  >.......j.O......<
001860 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001c00 22 54 68 69 73 20 69 73 20 61 20 74 65 73 74 20  >"This is a test <
001c10 66 69 6c 65 22 20 0d 0a 00 00 00 00 00 00 00 00  >file" ..........<
001c20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
05a000
wjones@DietPi:~/src/img$ hd mydbak.img
000000 eb fe 90 4d 53 44 4f 53 35 2e 30 00 02 02 01 00  >...MSDOS5.0.....<
000010 02 70 00 d0 02 fd 02 00 09 00 02 00 00 00 00 00  >.p..............<
000020 00 00 00 00 00 00 29 7c 00 e8 5d 4e 4f 20 4e 41  >......)|..]NO NA<
000030 4d 45 20 20 20 20 46 41 54 31 32 20 20 20 00 00  >ME    FAT12   ..<
000040 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
0001f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 aa  >..............U.<
000200 fd ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000210 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
000600 fd ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000610 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
000a00 54 45 53 54 20 20 20 20 20 20 20 10 00 00 00 00  >TEST       .....<
000a10 00 00 00 00 00 00 9d 6e 84 4f 02 00 00 00 00 00  >.......n.O......<
000a20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001800 2e 20 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >.          .....<
001810 00 00 00 00 00 00 9d 6e 84 4f 02 00 00 00 00 00  >.......n.O......<
001820 2e 2e 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >..         .....<
001830 00 00 00 00 00 00 9d 6e 84 4f 00 00 00 00 00 00  >.......n.O......<
001840 54 45 53 54 20 20 20 20 54 58 54 20 00 00 00 00  >TEST    TXT ....<
001850 00 00 00 00 00 00 b0 6e 84 4f 03 00 16 00 00 00  >.......n.O......<
001860 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001c00 54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 66  >This is a test f<
001c10 69 6c 65 2e 0d 0a 00 60 a9 16 eb 00 02 2f 00 00  >ile....`...../..<
001c20 46 44 49 53 4b 20 20 20 43 4f 4d 00 00 00 00 00  >FDISK   COM.....<
001c30 00 00 00 00 00 00 00 60 a9 16 f1 00 d8 df 00 00  >.......`........<
001c40 46 4f 52 4d 41 54 20 20 43 4f 4d 00 00 00 00 00  >FORMAT  COM.....<
001c50 00 00 00 00 00 00 00 60 a9 16 0d 01 8f 80 00 00  >.......`........<
001c60 4d 49 52 52 4f 52 20 20 43 4f 4d 00 00 00 00 00  >MIRROR  COM.....<
001c70 00 00 00 00 00 00 00 60 a9 16 1e 01 f9 46 00 00  >.......`.....F..<
001c80 33 43 35 58 39 50 44 20 43 4f 4d 00 00 00 00 00  >3C5X9PD COM.....<
001c90 00 00 00 00 00 00 ac 80 85 26 89 13 bc 31 00 00  >.........&...1..<
001ca0 53 48 41 52 45 20 20 20 45 58 45 00 00 00 00 00  >SHARE   EXE.....<
001cb0 00 00 00 00 00 00 00 60 a9 16 2a 01 90 2a 00 00  >.......`..*..*..<
001cc0 53 4d 41 52 54 44 52 56 53 59 53 00 00 00 00 00  >SMARTDRVSYS.....<
001cd0 00 00 00 00 00 00 00 60 a9 16 30 01 83 20 00 00  >.......`..0.. ..<
001ce0 53 59 53 20 20 20 20 20 43 4f 4d 00 00 00 00 00  >SYS     COM.....<
001cf0 00 00 00 00 00 00 00 60 a9 16 35 01 70 34 00 00  >.......`..5.p4..<
001d00 55 4e 44 45 4c 45 54 45 45 58 45 00 00 00 00 00  >UNDELETEEXE.....<
001d10 00 00 00 00 00 00 00 60 a9 16 3c 01 64 36 00 00  >.......`..<.d6..<
001d20 55 4e 46 4f 52 4d 41 54 43 4f 4d 00 00 00 00 00  >UNFORMATCOM.....<
001d30 00 00 00 00 00 00 00 60 a9 16 43 01 90 48 00 00  >.......`..C..H..<
001d40 58 43 4f 50 59 20 20 20 45 58 45 00 00 00 00 00  >XCOPY   EXE.....<
001d50 00 00 00 00 00 00 00 60 a9 16 4d 01 bc 3d 00 00  >.......`..M..=..<
001d60 44 4f 53 4b 45 59 20 20 43 4f 4d 00 00 00 00 00  >DOSKEY  COM.....<
001d70 00 00 00 00 00 00 00 60 a9 16 55 01 fc 16 00 00  >.......`..U.....<
001d80 44 4f 53 53 48 45 4c 4c 56 49 44 00 00 00 00 00  >DOSSHELLVID.....<
001d90 00 00 00 00 00 00 00 60 a9 16 58 01 f6 24 00 00  >.......`..X..$..<
001da0 54 43 50 20 20 20 20 20 20 20 20 10 00 00 00 00  >TCP        .....<
001db0 00 00 00 00 00 00 ee 10 24 c8 aa 04 00 00 00 00  >........$.......<
001dc0 44 4f 53 53 48 45 4c 4c 43 4f 4d 00 00 00 00 00  >DOSSHELLCOM.....<
001dd0 00 00 00 00 00 00 00 60 a9 16 63 01 02 12 00 00  >.......`..c.....<
001de0 44 4f 53 53 48 45 4c 4c 45 58 45 00 00 00 00 00  >DOSSHELLEXE.....<
001df0 00 00 00 00 00 00 00 60 a9 16 66 01 0e 98 03 00  >.......`..f.....<
001e00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
05a000
```

`mydbak.img` was created during a previous session and contains directory
entries from my AT hard disk, while `mydisk.img` does not. When I recreate
`mydisk.img` _yet again_, I see the same results- no directory entries.

It was at this point I realized I accidentally included quotes in `TEST.TXT`
while duplicating the layout of `mydbak.img`. On a hunch, I [deleted](#delete)
`mydisk.img` completely, created a new disk, and created `TEST` and `TEST.TXT`
_correctly_ this time. The hexdump of my new `mydisk.img` looks like this:

```
wjones@DietPi:~/src/img$ hd mydisk.img
000000 eb fe 90 4d 53 44 4f 53 35 2e 30 00 02 02 01 00  >...MSDOS5.0.....<
000010 02 70 00 d0 02 fd 02 00 09 00 02 00 00 00 00 00  >.p..............<
000020 00 00 00 00 00 00 29 1e 4a e9 5d 4e 4f 20 4e 41  >......).J.]NO NA<
000030 4d 45 20 20 20 20 46 41 54 31 32 20 20 20 00 00  >ME    FAT12   ..<
000040 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
0001f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 aa  >..............U.<
000200 fd ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000210 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
000600 fd ff ff ff ff ff 00 00 00 00 00 00 00 00 00 00  >................<
000610 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
000a00 54 45 53 54 20 20 20 20 20 20 20 10 00 00 00 00  >TEST       .....<
000a10 00 00 00 00 00 00 b7 6a 85 4f 02 00 00 00 00 00  >.......j.O......<
000a20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001800 2e 20 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >.          .....<
001810 00 00 00 00 00 00 b7 6a 85 4f 02 00 00 00 00 00  >.......j.O......<
001820 2e 2e 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >..         .....<
001830 00 00 00 00 00 00 b7 6a 85 4f 00 00 00 00 00 00  >.......j.O......<
001840 54 45 53 54 20 20 20 20 54 58 54 20 00 00 00 00  >TEST    TXT ....<
001850 00 00 00 00 00 00 10 6c 85 4f 03 00 17 00 00 00  >.......l.O......<
001860 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
001c00 54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 66  >This is a test f<
001c10 69 6c 65 2e 20 0d 0a 0e 24 c8 02 00 00 00 00 00  >ile. ...$.......<
001c20 2e 2e 20 20 20 20 20 20 20 20 20 10 00 00 00 00  >..         .....<
001c30 00 00 00 00 00 00 68 0e 24 c8 00 00 00 00 00 00  >......h.$.......<
001c40 43 4f 55 4e 54 52 59 20 53 59 53 00 00 00 00 00  >COUNTRY SYS.....<
001c50 00 00 00 00 00 00 00 60 a9 16 3f 00 16 45 00 00  >.......`..?..E..<
001c60 45 47 41 20 20 20 20 20 53 59 53 00 00 00 00 00  >EGA     SYS.....<
001c70 00 00 00 00 00 00 00 60 a9 16 48 00 15 13 00 00  >.......`..H.....<
001c80 4b 45 59 42 20 20 20 20 43 4f 4d 00 00 00 00 00  >KEYB    COM.....<
001c90 00 00 00 00 00 00 00 60 a9 16 4b 00 3b 3b 00 00  >.......`..K.;;..<
001ca0 4b 45 59 42 4f 41 52 44 53 59 53 00 00 00 00 00  >KEYBOARDSYS.....<
001cb0 00 00 00 00 00 00 00 60 a9 16 53 00 3e 95 00 00  >.......`..S.>...<
001cc0 4e 4c 53 46 55 4e 43 20 45 58 45 00 00 00 00 00  >NLSFUNC EXE.....<
001cd0 00 00 00 00 00 00 00 60 a9 16 66 00 6c 1b 00 00  >.......`..f.l...<
001ce0 44 49 53 50 4c 41 59 20 53 59 53 00 00 00 00 00  >DISPLAY SYS.....<
001cf0 00 00 00 00 00 00 00 60 a9 16 6a 00 a5 3d 00 00  >.......`..j..=..<
001d00 45 47 41 20 20 20 20 20 43 50 49 00 00 00 00 00  >EGA     CPI.....<
001d10 00 00 00 00 00 00 00 60 a9 16 72 00 e0 e5 00 00  >.......`..r.....<
001d20 48 49 4d 45 4d 20 20 20 53 59 53 00 00 00 00 00  >HIMEM   SYS.....<
001d30 00 00 00 00 00 00 00 60 a9 16 8f 00 20 2d 00 00  >.......`.... -..<
001d40 4d 4f 44 45 20 20 20 20 43 4f 4d 00 00 00 00 00  >MODE    COM.....<
001d50 00 00 00 00 00 00 00 60 a9 16 95 00 21 5c 00 00  >.......`....!\..<
001d60 53 45 54 56 45 52 20 20 45 58 45 00 00 00 00 00  >SETVER  EXE.....<
001d70 00 00 00 00 00 00 00 60 a9 16 a1 00 e1 2e 00 00  >.......`........<
001d80 41 4e 53 49 20 20 20 20 53 59 53 00 00 00 00 00  >ANSI    SYS.....<
001d90 00 00 00 00 00 00 00 60 a9 16 a7 00 3a 23 00 00  >.......`....:#..<
001da0 44 45 42 55 47 20 20 20 43 4f 4d 00 00 00 00 00  >DEBUG   COM.....<
001db0 00 00 00 00 00 00 00 60 a9 16 ac 00 8a 50 00 00  >.......`.....P..<
001dc0 45 44 4c 49 4e 20 20 20 43 4f 4d 00 00 00 00 00  >EDLIN   COM.....<
001dd0 00 00 00 00 00 00 00 60 a9 16 b7 00 52 31 00 00  >.......`....R1..<
001de0 45 4d 4d 33 38 36 20 20 45 58 45 00 00 00 00 00  >EMM386  EXE.....<
001df0 00 00 00 00 00 00 00 60 a9 16 be 00 5e 66 01 00  >.......`....^f..<
001e00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  >................<
*
05a000
```

I see directory entries yet again, and _they're not even the same ones present
in `mydbak.img`!_ Now I'm confident this behavior isn't intentional!

##### Delete
Because I'm cautious about creating virtual disks of densities/sizes that my
hardware doesn't support, I decided to delete `HDDISK`/`hddisk` to remove the
temptation:

```
C:\>ethflop d hddisk
Disk HDDISK has been deleted
```

On the server side, there are no surprises- `hddisk.img` is gone. If someone
_really_ wants it back, they can recreate it from the hexdump!

```
wjones@DietPi:~/src/img$ ls
msdos213.img  mtcpget.img  mydbak.img  mydisk.img
```

At this point, I had tested ethflop's functionality to my satisfaction and
turned off the AT for the day. I'm sure I'll be using both of them again very
soon.

## The Verdict
ethflop works pretty much flawlessly for accessing my myriad of floppy images
I've accumulated over the years. As if you couldn't guess, I love seeing old
hardware given a new lease on life. This applies especially when new software
_extends_ the functionality of old hardware to- or beyond- what it was capable
of during its useful life. So to [Mateusz Viste](http://mateusz.viste.fr/),
I sincerely thank you for writing ethflop!

I have a large number of floppy images I've accumulated over the years,
but not enough 5.25" floppies{{fn(id=6)}} to write them all. In the past I've
reused disks I've no longer needed (but had an image backup) in order to
"time division multiplex" floppy disks. But I have plenty of images which only
work properly as boot disks. Since I can't load ethflop during boot, I like to
save my physical floppies for stuff like install or rescue disks. I think I
will be using ethflop frequently from here on out for my vintage pursuits,
unless I'm just in the mood to play with _real_, physical floppy disks :).

### Future Ideas
I'm not in the right frame of mind to try this now, but I wonder if it'd be
possible to extend ethflop to emulate a virtual D:\\ drive (I dare not try
replacing drive C:\\!)? Or better yet, is it possible to extend ethflop into
an MSDOS block device driver instead of a TSR? What about systems with 4
floppy drives? They're rare, but the original IBM PC disk controller supports
them _in principle_{{fn(id=7)}}. Oh, and I think I can even use ethflop to
implement [`DISKCOPY`](https://en.wikipedia.org/wiki/Diskcopy) over the network
for unimaged floppies!

Mateusz Viste also wrote a [networked file system](http://etherdfs.sourceforge.net)
for DOS that I want to check out soon- that also might give me some ideas.
There are many neat DOS and floppy project ideas still waiting to be pulled
from the ether to give old machines new life...

<!-- ## Extra- How ethflop Works
If you're not interested in how DOS works (at a medium-high level), feel free
to skip reading this section. Otherwise, read on!

### Mini DOS Primer
If you _are_ interested in some DOS internals but haven't studied
them before, here is some relevant info for previous and remaining sections:

* A DOS device driver is a set of x86 routines honoring certain conventions
  that the DOS kernel uses to talk to hardware. Like Unix variants, DOS
  uses human-readable identifiers to identify device drivers. Unlike Unix
  variants, these identifiers become reserved names that can't be used for
  files.

  Additionally, like Unix flavors, DOS has two types of device drivers-
  character devices and block devices. Character device drivers implement
  MSDOS features such as `TYPE FOO.TXT > $DRIVER_NAME`. Block device drivers
  implement drive letters in DOS.

  Traditionally, DOS device drivers could only be loaded at boot by reading
  a file named `CONFIG.SYS`. The third-party `DEVLOAD` [program](https://www.infradead.org/devload/)
  provides code to load device drivers after boot. The story of `DEVLOAD` is
  quite fascinating if you're a DOS enthusiast, so I encourage others to
  read the Project Writeup.

* The DOS kernel can usually only handle a single task/executable at a time.
  It is possible to load routines that can be used by executables run at a
  later time that change the default behavior of DOS. These are known as
  Terminate and Stay Resident (TSR) programs. Most (all?) TSRs will [hook](https://stackoverflow.com/questions/37057157/what-does-interrupt-hooking-mean)
  x86 interrupts to change the behavior of DOS and the BIOS. Both DOS and the
  BIOS use [software interrupts](https://en.wikipedia.org/wiki/INT_(x86_instruction))
  or hardware interrupts (e.g. the floppy controller telling the CPU "I'm done
  transferring data!") to complete various tasks, like e.g. loading a file
  from floppy disk to memory.

### How ethflop Actually Works
ethflop is a TSR that hooks the (software) interrupt `0x13` floppy disk
services provided by the BIOS. Since DOS reuses BIOS-provided APIs in a
number of cases instead of reimplementing their functionality{{fn(id=8)}},
it is often sufficient to change BIOS functionality in order to change DOS
functionality.
-->

<!--
### Is ethflop Even Possible?
This section mainly exists because I wanted to document my initial
understanding of how ethflop works (and why I was drawn to it) versus my
current understanding! It is completely optional, so feel free to skip.

I didn't initially think ethflop was possible to implement within the
restrictions of a DOS environment. Thinking of workarounds/solutions to all
the issues I _perceived_ made me tap into knowledge I haven't used in years and
was otherwise a fun (for some value of fun) exercise.

I had some misconceptions about how ethflop works. Specifically, I thought
ethflop was a DOS block device driver that implemented the block device
routines via by Ethernet card's packet driver. Based on this misconception, I
was _very_ curious about ethflop's implementation; such a device driver would
not be easy to implement, and I would imagine a number of edge cases that
would crash DOS.

In the past, information about DOS
[data structure internals](http://stanislavs.org/helppc/sft.html)
and [device drivers](https://www.drdobbs.com/writing-ms-dos-device-drivers/184402277)
were hard to find online{{fn(id=2)}}.

Additionally, while I've heard of MSDOS device drivers that are basically
vestigial{{fn(id=3)}}, I'd never heard an MSDOS device driver that also
required a TSR to function. The ethflop website specifically mentions that
ethflop requires a packet driver, which is one TSR. Secondly, the executable
`ETHFLOP.COM` itself installs as a TSR.

A device driver which relied on one or more TSRs could not be loaded via
`CONFIG.SYS`

At th

I vaguely know such device drivers already exist, but I would be curious how
difficult it would be to implement basic network-attached storage as a DOS
block device driver of my own? Could I reuse the packet driver for this
(meaning `DEVLOAD`-only)? Could I somehow multiplex using the packet driver for
the device driver as well as a second DOS application that talks over the
network? I sense plenty of opportunities for beautiful and horrifying hacks!

### How ethflop Actually Works
After playing with ethflop, I ended up skimming the source to `ethflop.asm`
satisfy my own curiosity. Turns out I grossly misunderstood how ethflop works.
For starters, ethflop is a TSR that hooks
-->

## Footnotes
{% fntrg(id=1) %}
I've opened my 10BASE2 to 10BASET converter before; the conversion is done by
a chip that was manufactured by National Semiconductor in the early/mid-90s.
Unfortunately, its name escapes me, and I can't check in the immediate future.
{% end %}

{% fntrg(id=2) %}
I'm unsure if a "generic" packet driver exists, though I'm aware that the
packet driver spec maintainer <a href="http://russnelson.com">Russ Nelson</a>
used to have a generic template that vendors used to create their packet
drivers.
{% end %}

{% fntrg(id=3) %}
Interfacing DOS with the serial port could be a blog post in and of itself,
I'm afraid. It's very easy to get a very helpful <code>Write failure</code> or
<code>General failure</code> when accessing the serial port (e.g.
<code>COPY COM2 FOO.TXT</code> or <code>CTTY COM2</code>) just by breathing
wrong. What <em>best</em> matches my experience is that DOS uses <a href="https://en.wikipedia.org/wiki/RS-232#RTS,_CTS,_and_RTR">flow control</a>
for sending but not receiving (<a href="http://web.archive.org/web/20010817014431/http://www.algonet.se/~dennisgr/z88-dark.htm">Source</a>).
Disabling flow control in your serial terminal or transfer program is a safe
option.
{% end %}

{% fntrg(id=4) %}
I don't remember the exact details right now (and will check later), but I had
an old 8-bit ISA CNet NIC that required a few kB of <a href="https://en.wikipedia.org/wiki/Upper_memory_area">Upper Memory</a>.
The manufacturer-set default switches for the memory area- yes, this had to be
set manually!- conflicted with the memory area commonly used for hard drive
controller (segment <code>0xc800</code>). This was even mentioned in the manual I got with
the card, but of course I didn't read it first :).
{% end %}

{% fntrg(id=5) %}
Originally, the IBM PC had provisions for 4 floppy drives, though
I don't remember how DOS assigns drive letters in this case, especially in the
case where hard disks exist as well. This might be an interesting addition to
ethflop to keep Drives A:\ and B:\ free.
{% end %}

{% fntrg(id=6) %}
I think I have about 50 5.25" floppies overall? Over the years I've accumulated
approximately 30 Double Density (360kB) and 20 High Density (1.2MB) disks.
Sadly, it is easier for me to write and read 5.25" disks than 3.5" disks ever
since my USB floppy drive broke...
{% end %}

{% fntrg(id=7) %}
As far as I'm aware, no commercial product was ever released that used the
DB37 connector on the original IBM PC floppy controller ISA card. However, the
pinout matches the more traditional 34-pin edge connector, so an adapter
isn't difficult.
{% end %}

{% fntrg(id=8) %}
This is in contrast to x86 Linux, BSD, Windows, or any hobbyist OS using
<a href="https://en.wikipedia.org/wiki/Protected_mode">protected mode</a>.
While I imagine DOS started out using the BIOS services as a space saving
measure, I imagine there was also a backwards compatibility element later on
that made a more efficient reimplementation of BIOS services impossible.
{% end %}

<!-- {% fntrg(id=5) %}
In my opinion, info is _still_ hard to find though the situation has gotten
better. Back when I was actively learning about DOS, [DEVDRIV.DOC](https://github.com/microsoft/MS-DOS/blob/master/v2.0/bin/DEVDRIV.DOC)
didn't exist yet. I'll seek out my old [VCF](http://www.vcfed.org/forum/forum.php)
forum posts later, but aside from a PDF here and there, information on DOS data
structures and device driver internals were relegated to unscanned physical
books.
{% end %}

{% fntrg(id=6) %}
For instance, citation needed, but my current understanding of Expanded
Memory Managers is that the [EMM spec](http://www.phatcode.net/res/218/files/limems40.txt)
mandates loading a device driver to indicate that a manager is present via the
device name. However, there isn't actually any _code_ associated with the
device driver that DOS uses. Rather, all Expanded Memory routines are accessed
via x86 interrupt 0x67.
{% end %} -->
