+++
title = "Porting a New Board To Migen"
description = "A tutorial on creating a placement-constraints file (PCF) usable from the Migen Hardware Description Language (HDL)."
date = 2017-09-25
updated = 2019-06-09
aliases = ["blog/migen-port.html"]
+++

# Porting a New Board To Migen
*Taps mic* Is this thing on? So it's really been 11 months since I last
wrote something? I really need to change that! I'm going to _attempt_
to write smaller articles in between my larger, more involved ones to keep
me motivated to keep writing.

So today, I'm going to write about a simpler topic I meant to discuss last
year, but never got around to it: How to get started with
[Migen](https://github.com/m-labs/migen) on your Shiny New FPGA Development
Board! This post assumes you have previous experience with Python 3 and
experience synthesizing digital logic on FPGAs with Verilog.
_However, no Migen experience is assumed!_ Yes, you can port your a
development board to Migen without having used Migen before!

## What Is Migen- And Why Use It?
Migen is a Python library (framework, maybe?) to build digital circuits
either for simulation, synthesis on an FPGA, or ASIC fabrication (the latter
of which is mostly untested). Migen is [one](https://github.com/SpinalHDL)
[of](http://www.myhdl.org) [many](https://chisel.eecs.berkeley.edu)
attempts to solve some deficiences with Verilog and VHDL, the languages most
commonly used in industry to develop digital integrated circuits (ICs). If
necessary, a designer can use and import Verilog/VHDL directly into their
designs using one of the above languages too.

All the languages
above either emit Verilog or an [Intermediate Representation](https://github.com/freechipsproject/firrtl)
that can be transformed into Verilog/VHDL. I can think of a few reasons why:

1. FPGA synthesis/ASIC front-ends are typically proprietary, can't be readily
  modified, and mostly only support Verilog and VHDL as input.
2. Many issues with Verilog, such as synthesis-simulation behavior mismatch,
  don't occur if Verilog can be emitted in a controlled manner, as is done
  with the above languages.{{fn(id=1)}}
3. From my own experience looking at yosys, which can be used as the front-
  end Verilog compiler
  to an [open-source synthesis toolchain](http://www.clifford.at/icestorm/),
  there is little gain to targeting a file format meant for FPGA
  synthesis (or ASIC fabrication) directly from a higher-level language.
  Targeting the synthesis file format directly must be shown to be bug-free
  with respect to having generated Verilog _and then_ generating the
  synthesis file format from the Verilog; this is nontrivial.

The [Migen manual](https://media.readthedocs.org/pdf/mithro-migen/latest/mithro-migen.pdf)
discusses its rationale for existing, but the important
reasons that apply to me personally are that Migen:
* Avoids simulation-synthesis behavior mismatches in generated output.
* Makes it easy to automate digital logic design idioms that are tedious in
  Verilog alone, such as Finite-State Machines and Asynchronous FIFOs.
* Prevents classes of bugs in Verilog code, such as ensuring each signal
  has an initial value and unused cases in `switch` statements are
  handled.
* Handles assignments satisfying
  "same sensitivity list, multiple always blocks" by concatenating them all
  into a single `always` block, whereas Verilog forbids this for synthesis.
  In my experience, this increases code clarity.

As an added bonus, I can write a Migen design once and, within reason,
generate a bitstream of my design without needing a separate User
Constraints File (UCF) for each board that Migen supports. This facilitates
design reuse by others who may not have the same board as I do, but has a
new board with the required I/O peripherals anyway.

For the above reasons, I am far more productive writing HDL than I ever was
writing Verilog.{{fn(id=2)}}

### Choice of Tools Disclaimer
Of the linked languages above, I have only personally used Migen. Migen was
the first Verilog alternative I personally discovered when I started using
FPGAs for projects again in 2015 (after a 3 year break). When I first saw
the typical code structure of a Migen project, I immediately felt at home
writing my own basic designs, and could easily predict which Migen code
would emit which Verilog constructs without reading the source. In fact, I
ported my own Shiny New FPGA Development Board I just bought to Migen before
I even tested my first Migen design!

Because of my extremely positive first impressions, and time spent learning
Migen's more complicated features, I've had little incentive to learn a new
HDL. That said, I maintain it is up to the reader to experiment and decide
which HDL works best for their FPGA/ASIC projects. I only speak for my own
experiences, and the point of me writing this post is to make porting a new
board to Migen easier than when I learned how to do it. The code re-use
aspect of Migen is important to me, and when done correctly, a port to a new
board is very low-maintenance.

## Leveraging Python To Build FPGA Applications
To motivate how to port a new development board, I need to show Migen code
right now. If you haven't seen Migen before now, don't panic! I'll briefly
explain each section:

```
from migen import *
from migen.build.platforms import icestick

class Rot(Module):
    def __init__(self):
        self.clk_freq = 12000000
        self.ready = Signal()
        self.rot = Signal(4)
        self.divider = Signal(max=self.clk_freq)
        self.d1 = Signal()
        self.d2 = Signal()
        self.d3 = Signal()
        self.d4 = Signal()
        self.d5 = Signal()

        ###
        self.comb += [j.eq(self.rot[i]) for i, j in enumerate([self.d1, self.d2, self.d3, self.d4])]
        self.comb += [self.d5.eq(1)]

        self.sync += [
            If(self.ready,
                If(self.divider == int(self.clk_freq) - 1,
                    self.divider.eq(0),
                    self.rot.eq(Cat(self.rot[-1], self.rot[:-1]))
                ).Else(
                    self.divider.eq(self.divider + 1)
                )
            ).Else(
                self.ready.eq(1),
                self.rot.eq(1),
                self.divider.eq(0)
            )
        ]
```

If you've never seen Migen code before, and/or are unfamiliar with its
layout, I'll explain some of the more interesting points here in comparison
to Verilog:
* ```
  from migen import *
  from migen.build.platforms import icestick
  ```

  Migen by default exports a number
  of primitives to get started writing `Modules`.  Other Migen constructs,
  such as a library of useful building blocks (`migen.genlib`) and Verilog
  code generation (`migen.fhdl.verilog`) must be imported manually.
  `migen.build.platforms` contains all the FPGA development platforms Migen
  supports; the goal of this blog post will be to reimplement the
  [iCEstick](http://www.latticesemi.com/icestick) development board for use
  from Migen.

* ```
  class Rot(Module):
  ```

  A `Module` is the basic unit describing digital behavior in Migen.
  Connections between `Module`s are typically made by declaring instance
  variables that can be shared between `Module`s, and using `submodules`.
  Submodule syntax is described in the manual, and is required to share
  connections between modules.

* ```
  self.ready = Signal(1)
  ```

  A `Signal` is the basic data type in Migen. Unlike
  Verilog, which requires keywords to distinguish between data storage
  (`reg`) and connections/nets (`wire`), Migen can infer from a signal's
  usage whether or not the signal stores data. The `1` indicates the signal
  is one-bit wide.

* ```
  self.divider = Signal(max=self.clk_freq)
  ```

  In addition to providing a bit width, I can tell Migen the maximum value a
  `Signal` is expected to take, and Migen will initialize its width to
  `log2(max) + 1`. _However, nothing prevents the signal from exceeding max
  when run in a simulator or FPGA._

* ```
  ###
  self.comb += [j.eq(self.rot[i]) for i, j in enumerate([self.d1, self.d2, self.d3, self.d4])]
  ```

  By convention, data-type declarations are separated from code describing
  how code should behave using `###`. Migen statements relating connections
  of `Signal`s and other data types must be appended to either a `comb` or
  `sync` attribute. Connections are typically made using the `eq` function
  of `Signal`s. Python's slice notation accesses individual or subsets of
  bits of a `Signal`.

  `comb`, or combinationial, statements are analogous to Verilog's `assign`
  keyword or combinational `always @(*)` blocks, depending on the Migen data
  type/construct. In combinational logic, the output immediately
  changes in response to a changing or just-initialized) input without any
  concept of time (in theory).

* ```
  self.sync += [
          If(self.ready,
              If(self.divider == int(self.clk_freq) - 1,
                  self.divider.eq(0),
                  self.rot.eq(Cat(self.rot[-1], self.rot[:-1]))
              ).Else(
                  self.divider.eq(self.divider + 1)
              )
          ).Else(
              self.ready.eq(1),
              self.rot.eq(1),
              self.divider.eq(0)
          )
      ]
  ```

  By contrast, appending to the Migen `sync`, or synchronous, attribute emits
  Verilog code whose output only changes in response to a _positive edge_
  clock transition of a given clock, using the following syntax:
  `module.sync.my_clk += [...]`. If the clock is omitted, the clock defaults
  to `sys`.

  In synchronous/sequential logic, outputs do not change immediately in
  response to a changing or just- initialized input; the output only
  registers a new value based on its input signals in response to a low-to-
  high transition of another, usually periodic, signal. Migen only `always
  @(posedge clk)` blocks, so a `negedge` clock must be created by inverting
  an existing clock, such as `self.comb += [neg_clk.eq(~pos_clk)]`.

  As one might expect, `If().Elif().Else()` is analogous to Verilog `if`,
  `else if`, and `else` blocks. Migen will generate the correct style of
  `always` block to represent signal transitions regardless of whether the
  `If()` statement is part of a `comb` or `sync` block.

I omitted discussing any Migen data types, input arguments to their
constructors, other features provided by the package, and common code idioms
that I didn't use above for the sake of keeping this blog post on point.
Most of the user-facing features/constructors are documented in the user
manual. I can discuss features (and behavior) not mentioned in the manual in
a follow-up post.

## Adding a New Board
The [above code](#leveraging-python-to-build-fpga-applications) was adapted
from the [rot.v](https://github.com/cseed/arachne-pnr/tree/master/examples/rot)
example of Arachne PNR. In words, the above code turns on an LED, counts for
12,000,000 clock cycles, then turns off the previous LED and lights another
of 4 LEDs; after 4 LEDs the cycle repeats. A fifth LED is always kept on as
soon as the FPGA loads its bitstream.

Our goal is to get this simple Migen design to work on a new FPGA
development board, walking through the process. Since this example is
tailored to the iCE40 FPGA family, I'm choosing to port the iCEstick board
to Migen... which already has a port...

### Interactive Porting
My original intention was to write this blog post _while_ I was
creating the `icestick.py` platform file to be committed into `migen.build`.
Unfortunately, at the time, Migen did not have any support for targeting the
IceStorm synthesis toolchain.{{fn(id=3)}} So I ended up
[implementing](https://ssl.serverraum.org/lists-archive/devel/2016-May/004205.html)
the IceStorm backend and doing my blog post as intended went by the wayside
while debugging.

That said, I'm going to attempt to simulate the process of adding a board
from the beginning. I will only assume that the IceStorm backend to Migen
exists, but the `icestick.py` board file does not.

### We Need a Constraints File
Before I can start writing a board file for iCEstick, we need to know which
FPGA pins are connected to what. For many boards, the manufacturer will
provide a full User Constraints File (UCF) with this information. For
demonstrative purposes{{fn(id=4)}} however, I will examine the schematic
diagram of iCEstick instead to create my Migen board file. This can be found
in a file provided by Lattice at a changing URL called
"icestickusermanual.pdf".

We need to know the format of FPGA pin identifiers that Arachne PNR, the
place-and-route tool for IceStorm, will expect as well. The format differs
for each of the FPGA manufacturers and even between FPGA families of the same
manufacturer; Xilinx, for example uses `[A-Z]?[0-9]*`, as does the Lattice
ECP3 family. Fortunately, IceStorm uses pin numbers that correspond
to the device package, and these are easily visible on the schematic:

{% figure(alt="Page of iCEStick schematic", url="icestick-schem.png") %}
One side (port) of connections of the iCE40 FPGA to
iCEstick peripherals. In this image, LED, IrDA, and one side of 600 mil
breadboard-compatible breakout connections can be seen.
{% end %}

If we examine the schematic and user manual, we will find the following
peripherals:
* 5 LEDs
* 2x6 Digilient PMOD connector
* IrDA transceiver
* SPI Flash
* FT2232H UART (one channel- the other is used for programming)
* 16 Additional I/O pins

We might not have an actual _full_ constraints file to work with due to
how `arachne-pnr` works, but we have all the information to create a Migen
board file anyway, since we have the schematics. Armed with this
information, we can start creating a board file for iCEStick.

### Anatomy of a Migen Board File
Relative to the root of the migen package, migen places board definition
files under the `build/platforms` directory. _All paths in this section,
unless otherwise noted are relative to the package root._

#### Platform Class
```
from migen.build.generic_platform import *
from migen.build.lattice import LatticePlatform
from migen.build.lattice.programmer import IceStormProgrammer

class Platform(LatticePlatform):
    default_clk_name = "clk12"
    default_clk_period = 83.333

    def __init__(self):
        LatticePlatform.__init__(self, "ice40-1k-tq144", _io, _connectors,
            toolchain="icestorm")

    def create_programmer(self):
        return IceStormProgrammer()
```

A board file consists of the definition of Python `class` conventionally
named `Platform`. `Platform` should inherit from a class defined for each
supported FPGA manufacturer. As of this writing, Migen exports
`AlteraPlatform`, `XilinxPlatform`, and `LatticePlatform`, and more are
possible in the future. Vendor platforms are defined in a subdirectory under
`build` for each vendor, in the file `platform.py`.

Each FPGA vendor in turn inherits from `GenericPlatform`, which
is defined in `build/generic_platform.py` and exports a number of useful
methods for use in Migen code (I'll introduce them as needed). The
`GenericPlatform` [constructor](https://github.com/m-labs/migen/blob/master/migen/build/generic_platform.py#L230)
accepts the following arguments:

* `device`- A string indicating the FPGA device on your board.{{fn(id=5)}}
  The string format is vendor-toolchain specific; in the case of IceStorm,
  the format is currently `"ice40-{1k,8k}-{package}"`.
* `io`- A list of tuples of a specific format which I'll describe shortly.
  The list represents all non-user-expandable I/O resources on your current
  board. For instance, LEDs, SPI flash, and ADC connections to your FPGA
  would be placed in the `io` list.
* `connectors`- A list of tuples with a specific layout, which I'll describe
  shortly. The list represents user-expandable I/O that by default is not
  connecte to any piece of hardware, [Pmod](https://en.wikipedia.org/wiki/
  Pmod_Interface, Pmod) headers.
* `name`- I don't know what this input argument does exactly. Like other
  places in Migen with a `name` input argument, it's meant to control how
  variable names are generated in the Verilog output. I don't believe it's
  used by any board file, so I'm ignoring it.
* `toolchain`- The same FPGA vendor can have multiple software suites for
  their FPGA families, or third-party toolchains can exist. For instance,
  Xilinx has both the End-of-Life ISE Toolchain and Vivado software
  available. Additionally, Lattice provides the Diamond toolchain for their
  higher-end FPGAs while Project IceStorm is an unaffialited open-source
  synthesis flow for the iCE40 family. Thus, the vendor platform constructors
  [also supply](https://github.com/m-labs/migen/blob/master/migen/build/lattice/platform.py#L8)
  a `toolchain` keyword argument to choose which toolchain to eventually
  invoke. In the case of iCEStick, we use Migen's `icestorm` backend.

A `Platform` class definition should also define the class variables
`default_clk_name` and `default_clk_period`, which are used by
`GenericPlatform`. `default_clk_name` should match the name of a resource in
the `io` list that represents a clock input to the FPGA.
`default_clk_period` is used by vendor-specific logic in Migen to create a
clock constraint in nanoseconds for `default_clk_name`. _The default
clock is associated with the `sys` clock domain for `sync` statements._

Lastly, the `create_programmer` function should return a vendor-specific
programmer. Adding a programmer is beyond the scope of this article. If a
board can support more than one programming tool, the convention is to return
a programmer based on a [`programmer` class variable](https://github.com/m-labs/migen/blob/master/migen/build/platforms/minispartan6.py#L120-L126)
for the given board. This function can be omitted if no programmer fits, or
one can be created on-the-fly using `GenericPlatform.create_programmer`.

#### Finalization
Some platforms Migen supports, such as the
[LX9 Microboard](https://github.com/m-labs/migen/blob/master/migen/build/platforms/lx9_microboard.py#L119-L131),
have a `do_finalize` method. Finalization in Migen allows a user to defer
adding logic to their design until overall resource usage is known. In
particular, LX9 Microboard has an Ethernet peripheral, and the Ethernet
clocks should use separate timing constraints from the rest of the design.
The linked code detects whether the Ethernet peripheral was used using
`lookup_request("eth_clocks")` from `GenericPlatform`, and adds appropriate
platform constraints to the current design to be synthesized if necessary.
If the Ethernet peripheral was not used in the design, the extra constraints
are not added, and the `ConstraintError` from `lookup_request` is ignored.

Finalization operates on an internal Migen data structure
called `Fragment`s. `Fragment`s require knowledge of Migen internals to use
properly, so for the time being I suggest following the linked example if
you need to add constraints conditionally. Of course, timing constraints and
other User Constraints File data can be added at any point in your design
manually using `add_period_constraint` and `add_platform_command`
respectively, both from `GenericPlatform`.

iCEStick does not have any peripherals which need special constraints, and
only a single clock; Migen will automatically add a constraint for the
default clock. More importantly, in the case of IceStorm/iCEStick, only a
global clock constraint is supported due to limitations in specifying
constraints. Therefore, I omit the `do_finalize` method for the iCEStick
board file. However, one use I have found for `do_finalize`
in platforms compatible with IceStorm is to automatically instantiate pins
with pullup resistors enabled. This gets around the limitations of Arachne
PNR's constraints file format without needing to instantiate Verilog
primitives directly in the top level of a Migen source file, and I can show
code upon request.

#### I/O and Connectors
After defining a `Platform` class for your board, all you need to do
is fill in a list of `_io` and `_connectors` in your board file, pass
them into your `Platform`'s vendor-specific base class constructor, and
Migen will take care of the rest!

As I stated before, `io` and `connectors` input arguments to the
vendor-specific platform constructor are lists of tuples with a specific
format. Let's start with an I/O tuple:

```
io_name, id, Pins("pin_name", "pin_name") or Subsignal(...), IOStandard("std_name"), Misc("misc"))
```

An `io_name` is the name of the peripheral, and should match the string
passed into the `request` function to gain access to the peripheral's signals
from Migen. `id` is a number to distinguish multiple copies of identically-
functioning peripherals, such as LEDs. For simple peripherals, `Pins` is a
helper class which should contain strings corresponding to the vendor-
specific pin identifiers where the peripheral connects to the FPGA; in the
case of IceStorm, there are just the pin numbers as defined on the package
pinout. I will discuss `Subsignal`s in the next paragraph. These tuple
entries are used to create inputs and output names in the Migen-generated
Verilog, and provide a variable-name to FPGA pin mapping in a Migen-
generated User Constraints File (UCF)

Without going into excess detail{{fn(id=6)}},
`Subsignals` are a helper class for resources
that use FPGA pins which can be seperated cleanly by purpose. The inputs to
a `Subsignal` constructor are identical to an I/O tuple entry, except with
`id` omitted. The net effect for the end user is that a resource is
encapsulated as a class whose Migen `Signals`
are accessed via the class' members, i.e. `comb += [my_resource.my_sig.eq(5)]`.
This is known as a `Record` in Migen. `Records` also come with a number of
useful [methods](https://github.com/m-labs/migen/blob/master/migen/genlib/record.py)
for constructing Migen statements quickly. Think of them as analogous to C
`structs`. It is up to your judgment whether an I/O peripheral should use
`Subsignals`, but in general, I notice that Migen board files make heavy use
of them.

The remaining inputs to an I/O tuple entry are optional. `IOStandard` is
another helper class which contains a toolchain-specific string that
identifies which voltages/logic standard should use. And lastly, the `Misc`
helper class contains a space-separated string of other information that
should be placed into the User Constraints File along with `IOStandard`.
Such information includes [slew rate](https://github.com/m-labs/migen/blob/master/migen/build/platforms/mercury.py#L35')
and whether pullups should be enabled. _These are in fact currently ignored
in the IceStorm toolchain, but for my own reference I have filled them in as
necessary._

A connector tuple is a bit simpler:

```
(conn_name, "pin_name, pin_name, pin_name,...")
```

`conn_name` is analogous to `io_name`. The second element of a connector
tuple is a space-separated string of pin names matching the vendor's format
which indicates which pins on the FPGA are associated with that particular
connector. Ideally, the pins should be listed in some order that makes sense
for the connector.

By default, pins that are associated with connectors are not exposed by
the `Platform` via the `request` method. Instead, a user needs to
notify the platform that they wish to use the connector as extra I/O using
the `GenericPlatform.add_extension` method. Here is an example adding a
[PMOD I2C peripheral](https://blog.digilentinc.com/new-i2c-standard-for-pmods/)
using `add_extension`:

```
my_i2c_device = [
    ("i2c_device", 0,
        Subsignal("sdc", Pins("PMOD:2"), Misc("PULLUP")),
        Subsignal("sda", Pins("PMOD:3"), Misc("PULLUP"))
    )
]

plat.add_extension(my_i2c_device)
plat.request("i2c_device")
```

Note that adding a peripheral using `add_extension` is similar to adding
a peripheral to the `io` list, except that the `Pins()` element takes on
the form `"conn_name:index"`. `conn_name` should match a tuple in the
`connectors` list, and `index` is a zero-based index into the string
of FPGA pins associated with the connector. This allows you to create
peripherals on-the-fly that are (in theory) board and vendor-agnostic.

With the last concepts out of the way, let's jump right into creating the
`_io` and `_connectors` list for our Platform. Each listed peripheral
is implied to be a tuple inside `_io = [...] or _connectors = [...])`:

```
("user_led", 0, Pins("99"), IOStandard("LVCMOS33")),
("user_led", 1, Pins("98"), IOStandard("LVCMOS33")),
("user_led", 2, Pins("97"), IOStandard("LVCMOS33")),
("user_led", 3, Pins("96"), IOStandard("LVCMOS33")),
("user_led", 4, Pins("95"), IOStandard("LVCMOS33")),
```

`user_led`s are simple peripherals found on just about every development
board; iCEStick has 5 of them, all identical in function (but the 5th one is
green!). Resources with identical function that differ only in a pin should
each be declared in their own tuple, incrementing the `id` index.

Resource signal names are by convention; if a resource does not yet exist,
it's up to you what you want to name the resource. However, I suggest
looking at other board files for prior examples. `user_led`, `user_btn`,
`serial.rx`, `serial.tx`, `spiflash`, and `audio` are all commonly-used I/O
names used between board files.

```
("serial", 0,
    Subsignal("rx", Pins("9")),
    Subsignal("tx", Pins("8"), Misc("PULLUP")),
    Subsignal("rts", Pins("7"), Misc("PULLUP")),
    Subsignal("cts", Pins("4"), Misc("PULLUP")),
    Subsignal("dtr", Pins("3"), Misc("PULLUP")),
    Subsignal("dsr", Pins("2"), Misc("PULLUP")),
    Subsignal("dcd", Pins("1"), Misc("PULLUP")),
    IOStandard("LVTTL"),
),
```

Next we have another common peripheral- a UART/serial port. A UART peripheral
makes sense to divide using `Subsignal`s, since each pin has a distinct
purpose. Although in practice most users will only use `rx` and
`tx`{{fn(id=7)}}, I include all possible pins just in case. I don't remember
why I included `PULLUP` as constraints information for a majority of pins.
Note that it's perfectly okay to associate a constraint with all `Subsignal`s at once, as I do for the (unused) `IOStandard`.

```
("irda", 0,
    Subsignal("rx", Pins("106")),
    Subsignal("tx", Pins("105")),
    Subsignal("sd", Pins("107")),
    IOStandard("LVCMOS33")
),
```

The infrared port on iCEStick is another serial port, sans most of the
control signals. I omit the optional I/O tuple/`Subsignal` entries here, and
define the `IOStandard` similarly to the previous `serial` peripheral.

```
("spiflash", 0,
    Subsignal("cs_n", Pins("71"), IOStandard("LVCMOS33")),
    Subsignal("clk", Pins("70"), IOStandard("LVCMOS33")),
    Subsignal("mosi", Pins("67"), IOStandard("LVCMOS33")),
    Subsignal("miso", Pins("68"), IOStandard("LVCMOS33"))
)
```

`spiflash` and its `Subsignal` have standardized, self-explanatory names.
I suggest using these signal names when appropriate for all peripherals
connected via an [SPI bus](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus).
I don't remember why I added the `IOStandard` per-signal instead of all-at-
once here, but the net effect would be the same either way if IceStorm made
use of `IOStandard`.

```
("clk12", 0, Pins("21"), IOStandard("LVCMOS33")),
```

Clock signals should be included as well, with at least one clock's `io_name`
matching the `default_clk_name`. Migen may automatically `request` a clock
for your design if certain conditions are met; for now, assume you don't have
to `request` the clock.

```
("GPIO0", "44 45 47 48 56 60 61 62"),
("GPIO1", "119 118 117 116 115 114 113 112"),
("PMOD", "78 79 80 81 87 88 90 91"),
```

And lastly we have the connectors. The connector pins for `GPIO0-1` and
`PMOD` are ordered in increasing pin order, which matches the order they
are laid out on their respective connectors. _This is a happy coincidence.
Make sure to check your schematic and declare FPGA pins in connector order,
not the other way around!_

## Building Our Design For Our "New" Board
Now that we have created our board file, we now need to write the remaining
logic to attach the board's I/O to our <a href="#leveraging-python-to-build-
fpga-applications">Rot top level</a>. Assuming
the `Rot` module is already defined, we can create a script that will
synthesize our design like so:

```
if __name__ == "__main__":
    plat = icestick.Platform()
    m = Rot()
    m.comb += [plat.request("user_led").eq(l) for l in [m.d1, m.d2, m.d3, m.d4, m.d5]]
    plat.build(m, run=True, build_dir="rot", build_name="rot_migen")
    plat.create_programmer().flash(0, "rot/rot_migen.bin")
```

Once again, I will explain each line. It should be appended to the `Rot`
top level and then run using your Python 3 interpreter:

* ```
  plat = icestick.Platform()
  m = Rot()
  ```

  We create our platform and our `Rot` module here. `plat` contains a number
  of useful helper methods that help customize what is eventually sent to the
  synthesis flow.

* ```
  m.comb += [plat.request("user_led").eq(l) for l in [m.d1, m.d2, m.d3, m.d4, m.d5]]
  ```

  This list comprehension is how we actually connect our I/O to the LED
  rotation module. `plat.request("user_led")` will create a Migen `Signal`
  or `Record` which can be used to assign to `Signals` and `Records` in an
  existing `Module`. `GenericPlatform` does bookkeeping to figure out which
  `Signals` should be considered I/Os to/from the generated Verilog top
  level (and consequently, mapped to a User Constraints File).

  Repeatedly calling `request` for a given resource
  name will return a new `Signal` or `Record` of the same type, throwing a
  `ConstraintError` exception if there are no more available resources

* ```
  plat.build(m, run=True, build_dir="rot", build_name="rot_migen")
  ```

  The `GenericPlatform.build` function will emit Verilog output, a User
  Constraints File specific to your design, a batch file or shell script to
  invoke the synthesis flow, and any other files required as input to the
  synthesis toolchain. Optionally, Migen will invoke the generated script to
  create your design if input argument `run` is true. `build_dir` is self-
  explanatory, and `build_name` controls the filename
  of generated files.

  I pass in my top level `Rot` `Module` to the `build` function.
  `GenericPlatform` has internal logic to detect which signals were declared
  as I/O in the board file while generating Verilog input and output
  arguments.

* ```
  plat.create_programmer().flash(0, "rot/rot_migen.bin")
  ```

  This line is optional, but if included, Migen will invoke the `iceprog`
  FTDI MPSSE programmer for iCEStick automatically after creating a
  bitstream using IceStorm. The first input argument is the start address to
  start programming, and the second argument is the name of the output
  bitstream. The name can be inferred from `build_name` and the toolchain's
  default extension for bitstreams.

If all goes well, and you were following along, you should now have a
blinking LED example on your iCEStick! The final iCEStick platform board
file is [here](https://github.com/m-labs/migen/blob/master/migen/build/platforms/icestick.py),
which you can use as a reference, and I've made the `Rot` top level available
as a [gist](https://gist.github.com/cr1901/afc0442405fa4727802182ff9eac0e84).
Take a look at the output files Migen generated, including the output
Verilog and User Constraints File, to get a feel of how our "shiny new"
board file was used!

## Happy Hacking!
If you have read up to this point, you now have some grasp on the Migen
framework, and can now start using Migen in your own designs on your own
development (or even deployed) designs!

Porting Migen to support your design takes relatively little effort, and you
will quickly make up the time spent porting. Besides automating HDL idioms
that are tedious to write by hand (such as FSMs), and generating Verilog
that is free of certain bug classes, Migen saves time  as it automates
generating input files and build commands for your synthesis toolchain, and
then invoking the synthesis flow automatically. Additionally, if you write
your top-level `Module` and glue code correctly, you can have a single HDL
design that runs on all platforms that Migen supports, even between vendors,
with much less effort than is required to do the same in Verilog
alone!{{fn(id=8)}}

Migen is certainly a step in the right direction for the future of hacking
with FPGAs, and I hope you as the reader give it a try with your Shiny New
Development Board like I did, and see whether your experiences were as
positive as mine.

## Acknowledgements
I'd like to thank [Sébastien Bourdeauducq](https://twitter.com/m_labs_ltd),
the primary architect and maintainer of Migen, for looking over an initial
version of this post and offering feedback.

## Footnotes
{% fntrg(id=1) %}
For better or worse, emitting Verilog requires someone intimately
familiar with the Verilog specification. Like all good specifications, it is
terse, and requires a lot of memorization. But both Yosys and Migen are by
and large the work of one individual each, so it can be done.
{% end%}

{% fntrg(id=2) %}
In the interest of fairness, <a href="https://github.com/olofk/fusesoc">fusesoc</a>
exists now to alleviate the burdern of Verilog code-sharing. I was unaware of
its existence when I started using FPGAs again. I think Migen build i
ntegration would be an interesting project; in general, I find
setting up a board-agnostic Migen design easier than w/ FuseSoC, but
importing Verilog code as a package is still incredibly useful.
{% end%}

{% fntrg(id=3) %}
I erroneously assumed that because the Xilinx
backend code can use the yosys Verilog compiler that there was support for
support for yosys and by extension IceStorm in the Lattice backend. Not
having had any Lattice FPGAs before iCEstick (yes, I jumped on the FOSS FPGA
toolchain bandwagon), I never actually bothered to check beforehand!
{% end%}

{% fntrg(id=4) %}
Historically, I've found that IceStorm Verilog code samples only define the
pins their designs actually use. Unlike Quartus or ISE, Arachne PNR will
error out instead of warn if constraints that are defined aren't actually
used. Migen doesn't have this issue because it will only generate constraints
that are actually used for Arachne PNR.
{% end%}

{% fntrg(id=5) %}
Each <code>Platform</code> consists of a single FPGA and attached
peripherals. I assume a board with multiple FPGAs should implement a
<code>Platform</code> for each FPGA in a single board file.
{% end%}

{% fntrg(id=6) %}
Subsignals also <a href="https://github.com/m-labs/migen/blob/master/migen/build/generic_platform.py#L209-L221">modify</a>
how signal names are generated for the remainder of the synthesis toolchain.
{% end%}

{% fntrg(id=7) %}
iCEStick disappoints me in that the engineers wired <em>nearly</em> all the
connections required to use the FT2232H in FT245 queue mode, which is much
faster than a serial port; most dev boards do not bother connecting anything
besides serial TX and RX, and possibly RTS/CTS. But alas, there's still not
enough control connections to use queue mode.
{% end%}

{% fntrg(id=8) %}
Portability of code gives me joy, and HDL portability is no exception.
{% end%}
