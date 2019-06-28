+++
title = "Transitioning from Migen to nMigen"
description = "An nMigen primer for users familiar with original Migen (oMigen)."
date = 2019-06-27
aliases = ["blog/nmigen-for-omigen-users.html"]
draft = true
+++ 

# Transitioning from Migen to nMigen
[Migen](https://github.com/m-labs/migen) is a Python library designed for building
FPGA and ASIC applications that has seen what feels like 
[exponentially](https://github.com/m-labs/migen) 
[increasing](https://github.com/timvideos/HDMI2USB)
[usage](https://github.com/tinyfpga/TinyUSB) via word-of-mouth over the past
7 years. With many examples of Migen being used in production, the main
architects over at [M-labs](https://m-labs.hk) have noticed a number of
flaws with the language that have constituted a moderate reboot of the library
called [nMigen](https://github.com/m-labs/migen).{{fn(id=1)}}

While Migen (oMigen) continues to get updates for new targets and bug fixes,
the future direction of work on Migen from M-labs will be focused on nMigen.
A [compatibility layer](https://github.com/m-labs/nmigen/tree/master/nmigen/compat)
is provided so that designs _not using nMigen's `build`
modules_ can be ported seamlessly to nMigen with as little as a single import
change from `from migen import *` to `from nmigen.compat import *`.{{fn(id=2)}}

This post is meant to serve as an primer to quickly get started in nMigen for
someone familiar with oMigen. _The target audience comfortable with using a
large majority of oMigen features, although they need not know every single
parameter by memory of some of the more complicated oMigen constructs like
memories._

## High Level Overview of Differences
Without delving into syntax, and as someone still more familiar with writing
oMigen compared to nMigen, these are the major differences/similarities
I personally noted when writing nMigen code and synthesizing code to FPGAs:

* The fundamental unit of HDL code is still the `Module` and `submodules`,
  although their instantiation and adding HDL statements differs between
  oMigen and nMigen.
  
  In nMigen, `Module` creation needs to be done within the scope of a method
  called `elaborate`. You will typically subclass nMigen's `Elaboratable`,
  and add your input/output signals and `submodules` as class members accessible
  by `self` within `__init__`. You then also create a method known as
  `elaborate` in which you construct your `Module` using nMigen language
  constructs.
  
  `Fragment`s are also still present in nMigen, but have semantically different
  properties that are beyond the scope of this post.{{fn(id=3)}}

* nMigen breaks the cycle of FPGA tools targeting Verilog/VHDL only.
  
  nMigen generates [yosys's](https://github.com/YosysHQ/yosys) RTLIL
  Intermediate Representation (IR) as output rather than taking oMigen's Verilog
  generation approach. _This now means yosys is a hard dependency when using
  nMigen._
  
  For proprietary toolchains which can accept only Verilog or VHDL, yosys's
  `write_verilog` commmand is capable of converting back to Verilog from RTLIL.
  nMigen explicitly supports this use-case via `nmigen.back.verilog`.
  
  On the other hand, all FOSS toolchains for FPGAs currently (and for the
  foreseeable future, will) require yosys before the Place-And-Route (PNR) and
  bitstream generation. Since yosys will happily generate input files
  compatible with FOSS PNR tools{{fn(id=4)}} from RTLIL by design, this means
  that one can generate an FPGA bitstream using nMigen without needing to
  target Verilog first (beyond the Verilog libraries yosys uses internally)!

* nMigen uses Python [context managers](https://docs.python.org/3/reference/datamodel.html#context-managers)
  to implement flow control.
  
  Context managers mean it is now possible to pair `comb` and `sync` statements
  under the same `If/Else/Elif` and `Switch/Case` and `FSM` blocks. The context 
  managers have access to enough information to correctly handle statements 
  with the same trigger condition but different clock domains (including 
  combinational code). 
  
  This feature has no equivalent in oMigen, where flow control constructs were
  tied to a specific clock domain (or the comb "domain") via
  `self.sync += [If(..., ...).Else(...)]`. 
  
  `FSM`s are also implemented as a context manager in nMigen, whereas in oMigen
  they are implemented as plain Modules with a `do_finalize` method that hooks
  into oMigen internals to generate the required code correctly. Because one
  can associate multiple domains to the same trigger condition using context
  managers, the `NextValue` node, commonly used to build FSMs in oMigen, is no
  longer needed and thus has been removed. FSM ergonomics was one of the
  primary reasons for switching to context managers in nMigen, and will be
  demonstrated with sample code later.

* There are no more `Specials` and `do_finalize`.
  
  The lack of `Specials` affects how `Memories` and `Tristates` in particular
  are implemented, which I'll discuss later. Discussing the lack of 
  `do_finalize` is beyond the scope of this post.{{fn(id=3)}}
  
* nMigen supports yosys's formal verification facilities.
  
  This could be a blog post in and of itself and is beyond the scope of this
  post. That being said, _this is an nMigen exclusive feature, not available
  to the oMigen compatibility layer._
  
* The build system has been revamped, and is not compatible with `migen.build`.
  
  For most cases, the required changes are minimal burden (although I will
  briefly discuss internals later). As of this writing (6-27-2019), only
  targeting Xilinx Spartan 6, Xilinx Series 7, Lattice iCE40, and Lattice ECP5
  is supported, a subset of `migen.build`.

* Board files still exist, but now live in their own repository called
  [nmigen-boards](https://github.com/m-labs/nmigen-boards/).
  
  As of this writing (6-27-2019), porting a board to nmigen is a follow up post
  I intend to make soon. Board file layout is beyond the scope of this post.


## Writing nMigen Code By Comparison With oMigen
Now that I have summarized a high-level overview of nMigen and oMigen
differences, I will now demonstrate how to write nMigen code by comparing and
contrasting (effectively) functionally identical code snippets written in
both languages. The [previous](#high-level-overview-of-differences) section
will serve as a guide.

### Creating Modules

### If/Else/Elif

### Switch/Case

### FSMs

### Tristates

#### Other (I/O) Primitives
DDR I/O, etc. Good lead-in from Tristates

### Building A Design
#### RTLIL/Verilog Generation

#### Building using a Platform

## Next Steps
This post was ultimately meant to serve as a lead-in to porting your own FPGA
development board to nMigen. In my analogous [post](@/blog/migen-port.md) for
oMigen, I assumed a user had no prior Migen experience. Thus I gave a quick
[primer](@/blog/migen-port.md#leveraging-python-to-build-fpga-applications) 
on Migen before describing how to port a board. This matched my original 
experiences with oMigen in April 2015, where I in fact successfully ported a
[board](https://www.micro-nova.com/products/me1b) before I could ever test it
at the bench.

For the analogous nMigen post, my intent was to inline _this_ entire post
into the porting a new board post, while _also_ giving a quick primer for those
wh have never seen oMigen _or_ nMigen. This way, I felt I was accommodating
multiple skill levels. However, I soon figured out there's enough information
about oMigen and nMigen differences that it was best to create this post as
a prerequisite for previous oMigen users.

That said, I hope this post is useful in and of itself for those familiar with
oMigen and [LiteX](https://github.com/enjoy-digital/litex) for getting started
with the future direction of Migen development. As someone fairly
satisfied{{fn(id=5)}} with nMigen's design decisions, I look forward to what new
designs people have to offer in nMigen.

## Acknowledgements
I would like to thank [whitequark](https://twitter.com/whitequark) and
[Sébastien Bourdeauducq](https://twitter.com/m_labs_ltd), both of M-labs, for
looking over drafts of this post and offerring valuable overall feedback and
catching typos.

## Footnotes
{% fntrg(id=1) %}
While I am involved with submitting new features to nMigen not in (o)Migen,
I was/am not personally involved design decisions of nMigen core. I defer a
blog post or discussion of nMigen design decisions to someone at M-labs.
{% end %}

{% fntrg(id=2) %}
Miscompilation of code using the nMigen compatibility layer that previously
worked in oMigen is considered a good bug report :).
{% end %}

{% fntrg(id=3) %}
This should be read as "I am not currently qualified to discuss the differences,
and while I think they're important, I am deferring discussion to an update
to this post" :).
{% end %}

{% fntrg(id=4) %}
There are a 
<a href="https://github.com/YosysHQ/nextpnr#other-foss-fpga-place-and-route-projects">number</a>
of FOSS PNR tools in various states of development, but the primary two
currently used by projects are
<a href="https://github.com/YosysHQ/nextpnr">nextpnr</a> and
<a href="https://github.com/YosysHQ/arachne-pnr">arachne-pnr</a>.

Nextpnr is preferred for all new projects because it is FPGA-family agnostic
and just about superior to arachne-pnr in features (multiple clock constraints,
timing-driven placement) and resultant bitstream quality in every way.
{% end %}

{% fntrg(id=5) %}
<a href="/about/#contact-info">Ask</a> me personally if you're interested in my critiques :).
{% end %}


