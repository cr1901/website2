+++
title = "NMOS IC Reverse Engineering"
description = "The first in a series of posts about how to analyze (old!) silicon die images and extract transistors to study the underlying circuit."
date = 2016-10-12
aliases = ["blog/nmos-sample.html"]
+++

# NMOS IC Reverse Engineering

Recently, I was <del>tricked</del> <ins>talked</ins> into examining the die
of an integrated circuit (IC)- the YM2151, a single-chip FM synthesizer. I
like these old Yamaha chips, so I don't really mind doing it, but it's
definitely a long term project that I expect to take months. However, one
doesn't need to RE a significant portion of an IC to understand the basics
of RE. Information about a chip's operation can be gleamed by examining
small units, and predicting their relation to each other.

Information on doing IC reverse-engineering is still kind of limited,
although projects like [siliconpr0n](https://siliconpr0n.org) and whatever
[Ken Shirrif](http://www.righto.com/2014/10/how-z80s-registers-are-implemented-down.html)
is working on at any given time are changing that. Since I am learning how
to RE ICs, I decided to document how I decoded a small ROM in the YM2151
that I _suspect_ is being used as part of the control state machine. This
small ROM demonstrates the basics of REing ICs, including:

* Separating the various layers of an IC die.
* Mapping ROM inputs and outputs.
* Manually reading out the ROM contents.

## Obtaining a Die Image

Before we can examine an IC die, we have to actually digitally capture an
image of the die. I will not be discussing this in detail, but getting a die
image typically involves:

* Removing the IC package with corrosive chemicals, called decap.
* Taking a number of pictures using a digital camera with a microscope.
* Stitching all the individual images together to produce a full map of the
  IC die with individual transistors visible.

I really don't have access to the equipment to do this even at a small scale,
but luckily this work was done previously in the case of YM2151 (20x
magnification). I defer to Travis Goodspeed's article in section 9 of [POC||GTFO #4](https://archive.org/details/pocorgtfo04))
if interested in doing decap yourself.

{% figure(alt="YM2151 die image.", url="ym2151_die.png") %}
Die image of YM2151 at 20x magnification, full die. The full-size
image is 617MB <a href="https://siliconpr0n.org/map/yamaha/ym2151/mz_mit20x/">Source</a>.
{% end %}

## What is NMOS?
The YM2151 uses an [NMOS process](https://en.wikipedia.org/wiki/Depletion-load_NMOS_logic).
The NMOS logic family uses n-type metal oxide semiconductor field-effect
transistors (MOSFETs) to create digital logic gates. MOSFETs are four-
terminal devices that either permit or prevent current from flowing between
two of the terminals, called the drain and source, depending on the voltage
of the third terminal, called the gate, relative to either the drain or
source. The fourth terminal, called the body, is negligible for now.

### MOSFET Schematic Symbols
The below picture shows two different types of MOSFETS:
n-type depletion and n-type enhancement mode. On each MOSFET, the center
terminal attached to the left column is the gate input. The source and drain
are the bottom and top terminals, respectively. Each MOSFET has the source
connected to a fourth terminal, which in turn connects to an arrow pointing
inward to the right column, indicating n-type MOSFETs. Put simply, the arrow
direction corresponds to device polarity at a specific area within the
MOSFET. The source-body connection is a side effect of the MOSFET symbol I
used, and we can ignore it. A segmented right column represents enhancement
mode, and a solid right column represents depletion mode.

{% figure(alt="Two NMOS Circuits showing the schematic symbols for MOSFETs.", url="NMOS-Intro.png") %}
A depletion and enhancement mode n-type MOSFET circuit and an equivalent
circuit. The depletion mode MOSFET acts as a resistor, and the enhancement
mode MOSFET as a switch. A quick rationale on the schematic symbol is given
in the above paragraph. On is 5V, off 0V.
{% end %}

A MOSFET is a symmetrical device, so drain and source can be
labeled arbitrarily. However, according to Sedra and Smith, drain is by
convention always at a higher voltage than source.

### Quick "Theory" of MOSFETs
"n-type" refers to the properties of the silicon that carries current through
a MOSFET. For the purposes of this blog post, I need not go into its
properties.

In hand-calculations, a MOSFET has at least three [modes of operation](https://en.wikipedia.org/wiki/MOSFET#Modes_of_operation).
I'm not interested in doing simulation in this blog post (maybe in the
future I will!), but for completeness, the regions are:

* Cutoff, no conduction from drain to source.
* Triode, linear region, acts like a resistor.
* Saturated, increasing gate voltage does not increase current.

<!-- <p>When operating MOSFETs as gates/switches, we are typically
interested in cutoff and the linear region so we can create voltage dividers
with well-defined resistances. This way, the entire circuit can operate at
the proper on and off voltage ranges. This is called "ratioed logic",
according to LINK(`http://web.cs.mun.ca/~paul/transistors/node1.html', `this
useful page')</p>
-->

<!-- http://ece424.cankaya.edu.tr/uploads/files/Chap16-1-NMOS-Inverter.pdf -->

Both enchancement mode and depletion mode MOSFETs are used in the NMOS logic
family. Depletion-mode MOSFETs conduct current even when the gate and
source is at the same voltage; the gate must have a lower voltage than the
source for cutoff to occur. They are commonly, _but not exclusively_, used
as pullup resistors, operating in the linear region and always on.

On the other hand, enhancement-mode MOSFETs are used to implement logic
gates by either allowing current to pass or not. They operate in cutoff and
saturation. The gate must be at a higher voltage than the source to conduct
current. Voltage drop tends to be negligible in the enhancement-mode
MOSFETs; see ratioed logic in the previous link for more information.

With the above two paragraphs in mind, here is an exercise: How would you
implement an NMOS NOR gate (hint: MOSFETs in parallel)? NAND gate (hint:
MOSFETs in series)? Inverter (NOT) (hint: Look carefully at my MOSFET image)?
Notice how gates with inverters are easiest to implement?
I wonder if that's a reason active-low inputs and outputs are so common in
these chips?

### Am _I_ Dealing With NMOS?
How does one detect an NMOS chip? To be honest, I was told ahead of time that
the YM2151 uses an NMOS process. The year that this chip was first produced
(1984-5) is also a hint. Howvever, when compared to [CMOS die](https://siliconpr0n.org/map/yamaha/ymf262-m/mz_mit50xn)
of a similar-era Yamaha chip, I notice a few differences:

* Only one size of via in a CMOS die, many in NMOS.
* No obvious indication of pullup MOSFETs in CMOS, prevalent in NMOS.
* The CMOS die is more neatly organized, compared to NMOS.

Right now, the above list probably isn't all that meaningful :P. I'll discuss
what I mean in the next section. As you may expect, my method of analysis
only works for ICs made with an NMOS process. However, this is still useful
for preserving many old chips where fully emulating their behavior is
desired (YM2151) or even required (security chips) to preserve hardware.

## IC Layers
I decided to digitize (or vectorize) a ROM at the top of the chip,
approximately one third of the length longways.

{% figure(alt="Empty section of YM2151 die to be vectorized.", url="Capture_1.PNG") %}
Section of the YM2151 I intend to vectorize, before we begin any work.
{% end %}

ICs- well, not cutting-edge ones anyway- tend to be made by applying planar
layers of conducting and semiconductor material. Therefore, it tends to be
safe to represent each layer of material as a 2d layer in a vector image,
not worrying about layer depth or wells that would be apparent in a 3d
cutaway. Each layer can thus be inferred and by examining intersections and
outlines left over during decap.

I can tell the above is a ROM from the equal-width strips of metal (remember,
metal tends to be consistently colored) and the circular "holes" distributed
throughout the metal strips. These "holes" are properly referred to as
"vias". Vias are drilled holes, forming a connection with any layer that
intersects at their location.

Additionally, there exist buried contacts that directly connect (typically?
always?) the poly and active layers. A metal layer can be placed on top of a
buried contact without creating a connection. Buried contacts can frequently
be identified by a light square outline where poly and active intersect, but
this is not guaranteed. Sometimes buried contacts must be inferred from
context. The takeaway here is: vias and buried contacts form two additional
logical layers that need to be vectorized.

Buried contacts are different from MOSFET gates b/c a MOSFET gate is not a
direct connection. A gate has a layer of insulating oxide separating the
polysilicon and the active layer/wells underneath. However, it tends to be
obvious from context and visual inspection which type of connection exists,
even without having a 3d cutaway view which would show the differences.

Not all ICs have the same number of layers or the same layer material type,
but in the case of NMOS, it's safe to divide an IC die into at least three
layers:

* Metal, conducting material. Typically a whiteish hue that stands out, in
  the case of aluminum (which is what YM2151 uses).
* Polysilicon, pure silicon. Used for MOSFET gates. Color cannot be assumed,
  but outlines are obvious.
* Active, doped silicon used for drain and source. Color cannot be assumed,
  but outlines are obvious.

## Let's Digitize!
With the above out of the way, let's digitize the metal layer and vias of
the ROM. Please note that in some images that I may miss a section :P. I
correct it in a later step unless otherwise noted.

<table>
<caption>Layer Color Table</caption>
<thead><tr><td>Layer</td><td>Color</td></tr></thead>
<tbody>
<tr><td>Metal</td><td>Yellow</td></tr>
<tr><td>Polysilicon</td><td>Red</td></tr>
<tr><td>Active</td><td>Blue</td></tr>
<tr><td>Via</td><td>Green</td></tr>
<tr><td>Buried Contact</td><td>Pink</td></tr>
</tbody>
</table>

{% figure(alt="ROM inputs digitized.", url="Capture_2.PNG") %}
Metal layer is easily visible. Here, the ROM matrix, ROM inputs and power
and ground rails are digitized. I will show how to infer the latter three
shortly.
{% end %}

{% figure(alt="Vias vectorized.", url="Capture_3.PNG") %}
Here, we have digitized most of the vias of interest.
{% end %}

The image has become a bit crowded after digitizing the metal and via
layers, so for the time being I will disable them.

Let's start looking for transistors. I personally like to start with
pullups, becausepullups have a very distinctive shape on an NMOS die, and
the power rail can also be inferred. As mentioned before, NMOS pullups are
depletion-mode MOSFETs, and they have very large gate widths to create a
current path even without an applied gate voltage. Additionally, to provide
the pullup effect, there exists a connection to the active layer on the
source side of the MOSFET that
looks like a hook.

Pullup MOSFETs thus tend to look like "rectangles with a hook", with
slightly more emphasis on the hook to create the source-to-gate connection.
We can now safely vectorize the pullups, and immediate polysilicon traces
emanating from the pullups.

{% figure(alt="First depletion mode MOSFET vectorized!", url="Capture_4.PNG") %}
We have vectorized our first MOSFET gate! A depletion mode MOSFET at that.
{% end %}

{% figure(alt="All depletion mode MOSFETs vectorized!", url="Capture_5.PNG") %}
All pullups, polysilicon layer, vectorized. By process of elimination we
know the remaining two sides of the ROM are the inputs or outputs.
{% end %}

In our depletion mode pullups, the active layer consisting of source and
drain runs through the center of the wide gate. We can trace out the active
layer completely now, but I deliberately stopped short. The crossing of two
layers near the pullups at the bottom is signficant.

{% figure(alt="Starting to vectorize the active layer.", url="Capture_6.PNG") %}
We can start vectorizing the active layer that forms the source and drain of
the pullups.
{% end %}

Notice that each strip of the metal layer connecting at the top of the ROM
terminates in a via. The via connects to a layer below, either active or
poly, that runs across the length of the ROM. This layer abruptly terminates
after crossing the active layer that directly connects to the pullup's
source. There was a transistor formed due to that crossing during
fabrication! We can safely assume them to be enhancement mode
transistors used as switches due to the gate size.

Our unknown layer _must_ be poly because they form the gate of a transistor.
Furthermore, Because the metal at the top of the ROM attaches directly to
the gate of a transistor for each input, the top of the ROM must be our
input. By process of elimination, the output of our ROM is on the right.

{% figure(alt="Extraction of enhancement-mode transistors.", url="Capture_7.PNG") %}
Our first enhancement mode transistors. Notice how much smaller the gate is
for each compared to depletion mode.
{% end %}

Now I decided to take a break from the poly and vectorize the buried
contacts. The buried contacts in this section are all visible as squares at
poly and active crossings. Since a pullup _must_ have a buried contact to
connect the gate and source, let's start with the pullups. Can you find the
outline of the other buried contacts before scrolling to the second image?

{% figure(alt="A few buried contacts have been vectorized.", url="Capture_8.PNG") %}
Some buried contacts due to pullup connections have been digitized.
All buried contacts of interest in this section are visible.
{% end %}

{% figure(alt="Same image as above, but with all remaining buried contacts vectorized.", url="Capture_9.PNG") %}
Remaining buried contacts of interest digitized.
{% end %}

Now, I finish the active layer, which by process of elimination is going to
be the remaining unvectorized traces. These form a number of enhancement-
mode MOSFET switches distributed through the ROM matrix. _Anywhere the poly
crosses the active layer is a transitor!_

{% figure(alt="Active layer has been digitized. The ROM is fully vectorized, but not all layers are visible.", url="Capture_11.PNG") %}
Remaining active layer forming the ROM matrix digitized. I accidentally
missed part of the active layer at the bottom of the second column when
taking these images.
{% end %}

With the active layer (minus my mistake) digitized, the ROM has been fully
vectorized. I re-enable the metal and via layers to show the final result.
Additionally, I vectorized a few more sections all all layers, only one of
which is relevant to the ROM.

The thick metal trace below the ROM which connects to the active layer of
the ROM matrix (at the source terminals of the enhancement mode MOSFETs
immediately attached to depletion mode pullups), is in fact a ground trace.
From experience, I can expect the active columns running through
the ROM matrix to be connected to ground. I will explore why in the next
section.

{% figure(alt="Fully vectorized ROM with all layers visible.", url="Capture_13.PNG") %}
Fully vectorized ROM, plus some extra connections.
{% end %}

## Schematic Capture
I am arbitrarily labeling the leftmost and bottommost bus lines the LSBs of
the input and output, respectively. Thus, bit positions increase as one
travels from left to right and bottom to top of the ROM matrix.

Initially, I had intermediate images of my progress creating the schematic.
Unfortunately, for various formatting reasons (repeated transistor numbers,
inconsistent resolution), the intermediate images didn't turn out how I liked, so I removed them.

I created the schematic in a manner very similar to how I vectorized
starting with the pullups, then adding the inputs and their corresponding
MOSFET switch connections. Then I added the ROM outputs. Next, I added the
remaining wires that run down the ROM matrix columnwise, which attach to the
source of the switch enhancement mode MOSFETs and pullup depletion-mode
MOSFETs respectively. I finished schematic capture by adding the additional
switch transistors that exist anywhere the active layer crosses poly within
the matrix.

For each trio of column wires, the leftmost wire is the ROM input, the middle
wire is the active layer running across each row of the ROM matrix, and the
rightmost wire is attached to its corresponding pullup.

<!-- <strong>I didn't realize that the thick trace below the ROM was a
ground trace until after I was done creating the schematic. So GND is not
present until the last image.</strong>

SCHEM(1, `Schematic considering only pullups.')
SCHEM(2, `Input bus lines and MOSFET inteface added to schematic.')
SCHEM(3, `')
SCHEM(4, `') -->

{% figure(alt="Fully extracted schematic of our vectorized region of interest in terms of MOSFETs.", url="NMOS-RE-Sample_6.png") %}
Full schematic. This 5x10 ROM contains nearly 60 transistors!
{% end %}

I made a mistake when drawing the above schematic. By convention, the source
should be at a lower voltage than the drain, but for the transistors within
the ROM matrix, I accidentally swapped source and drain. In an IC, this does
not matter, as a MOSFET is symmetric and swapping source and drain does not
affect device operation (for our intents and purposes). However, without
this disclaimer, I'm sure I will confuse people. Perhaps the drain and
source distinction is best ignored for this schematic.

## Reading Out the ROM Contents
With the above schematic, we can gleam some interesting information about
how the ROM works. I assume the ROM inputs are either always a valid 1 or 0,
because I am assuming that this ROM is driven by internal control logic.

If any given bus input is 0, the input will not turn on the switch
transistors at the bottom of the ROM, placed immediately before pullups.
This means that the pullups are not actively driven low, and the source
terminal of the pullups remains at a high logic value. The logical high is
propogated to all transistors whose gates are connected to the pullup
source; these transistors are on. All transistors whose gates are
attached to the bus input are in cutoff and have no effect on circuit
operation.

Notice that the metal corresponding to each bit output is attached to all
transistors in a row in parallel. This means that if _any_ of the
transistors in a given row are on, the entire metal row, and consequently
the output, is pulled low as well. This is also called [wired-AND](https://en.wikipedia.org/wiki/Wired_logic_connection).

In a similar manner, if any given bus input is 1, the input will turn on the
switch transistor and the logical level at the pullup source will be driven
low. All transistors whose gates are attached to the pullup source terminal
will be in cutoff and will not drive the metal strips low. However, because
the bus input is logical high, any transistors whose gate is attached to the
bus input will drive its corresponding bit output low.

We now have enough information to devise boolean expressions and a truth
table for the entire ROM!

<table>
<caption>Output Bits Driven Low For Each Input Bus Line</caption>
<thead><tr><td>Bus Line+Value</td> <td>Output Bits Driven Low</td></tr></thead>
<tbody>
<tr><td>I<sub>0</sub> High</td> <td>O<sub>1</sub>, O<sub>6</sub>, O<sub>7</sub></td></tr>
<tr><td>I<sub>0</sub> Low</td>  <td>O<sub>0</sub>, O<sub>5</sub>, O<sub>8</sub>, O<sub>9</sub></td></tr>
<tr><td>I<sub>1</sub> High</td> <td>O<sub>0</sub>, O<sub>3</sub>, O<sub>6</sub>, O<sub>7</sub></td></tr>
<tr><td>I<sub>1</sub> Low</td>  <td>O<sub>1</sub>, O<sub>4</sub>, O<sub>5</sub>, O<sub>8</sub>, O<sub>9</sub></td></tr>
<tr><td>I<sub>2</sub> High</td> <td>O<sub>2</sub>, O<sub>5</sub>
<tr><td>I<sub>2</sub> Low</td>  <td>O<sub>0</sub>, O<sub>1</sub>, O<sub>3</sub>, O<sub>4</sub>, O<sub>6</sub>, O<sub>7</sub>, O<sub>8</sub>, O<sub>9</sub></td></tr>
<tr><td>I<sub>3</sub> High</td> <td>O<sub>1</sub>, O<sub>2</sub>, O<sub>3</sub>, O<sub>6</sub>, O<sub>7</sub></td></tr>
<tr><td>I<sub>3</sub> Low</td>  <td>O<sub>0</sub>, O<sub>4</sub>, O<sub>5</sub>, O<sub>8</sub>, O<sub>9</sub></td></tr>
<tr><td>I<sub>4</sub> High</td> <td>O<sub>6</sub></td></tr>
<tr><td>I<sub>4</sub> Low</td>  <td>O<sub>0</sub></td></tr>
</tbody>
</table>

<table>
<caption>Output Bus Line Equations</caption>
<thead><tr><td>Bus Line</td> <td>Boolean Expression</td></tr></thead>
<tbody>
<tr><td>O<sub>0</sub></td>   <td>~(~I<sub>0</sub> | I<sub>1</sub> | ~I<sub>2</sub> | ~I<sub>3</sub> | ~I<sub>4</sub>)</td></tr>
<tr><td>O<sub>1</sub></td>   <td>~(I<sub>0</sub> | ~I<sub>1</sub> | ~I<sub>2</sub> | I<sub>3</sub>)</td></tr>
<tr><td>O<sub>2</sub></td>   <td>~(I<sub>2</sub> | I<sub>3</sub>)</td></tr>
<tr><td>O<sub>3</sub></td>   <td>~(I<sub>1</sub> | ~I<sub>2</sub> | I<sub>3</sub>)</td></tr>
<tr><td>O<sub>4</sub></td>   <td>~(~I<sub>1</sub> | ~I<sub>2</sub> | ~I<sub>3</sub>)</td></tr>
<tr><td>O<sub>5</sub></td>   <td>~(~I<sub>0</sub> | ~I<sub>1</sub> | I<sub>2</sub> | ~I<sub>3</sub>)</td></tr>
<tr><td>O<sub>6</sub></td>   <td>~(I<sub>0</sub> | I<sub>1</sub> | ~I<sub>2</sub> | I<sub>3</sub> | I<sub>4</sub>)</td></tr>
<tr><td>O<sub>7</sub></td>   <td>~(I<sub>0</sub> | I<sub>1</sub> | ~I<sub>2</sub> | I<sub>3</sub>)</td></tr>
<tr><td>O<sub>8</sub></td>   <td>~(I<sub>0</sub> | ~I<sub>1</sub> | ~I<sub>2</sub> | ~I<sub>3</sub>)</td></tr>
<tr><td>O<sub>9</sub></td>   <td>~(I<sub>0</sub> | ~I<sub>1</sub> | ~I<sub>2</sub> | ~I<sub>3</sub>)</td></tr>
</tbody>
</table>

<table>
<caption>Extracted ROM Contents of Analyzed Section. Underscores
are for clarity.</caption>
<thead><tr><td>Input Bus</td>  <td>Output Bus</td></tr></thead>
<tbody>
<tr><td>0b0_0000</td>  <td>0b00_0000_0100</td></tr>
<tr><td>0b0_0001</td>  <td>0b00_0000_0100</td></tr>
<tr><td>0b0_0010</td>  <td>0b00_0000_0100</td></tr>
<tr><td>0b0_0011</td>  <td>0b00_0000_0100</td></tr>

<tr><td>0b0_0100</td>  <td>0b00_1100_1000</td></tr>
<tr><td>0b0_0101</td>  <td>0b00_0000_1000</td></tr>
<tr><td>0b0_0110</td>  <td>0b00_0000_0010</td></tr>
<tr><td>0b0_0111</td>  <td>0b00_0000_0000</td></tr>

<tr><td>0b0_1000</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b0_1001</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b0_1010</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b0_1011</td>  <td>0b00_0010_0000</td></tr>

<tr><td>0b0_1100</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b0_1101</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b0_1110</td>  <td>0b11_0001_0000</td></tr>
<tr><td>0b0_1111</td>  <td>0b00_0001_0000</td></tr>

<tr><td>0b1_0000</td>  <td>0b00_0000_0100</td></tr>
<tr><td>0b1_0001</td>  <td>0b00_0000_0100</td></tr>
<tr><td>0b1_0010</td>  <td>0b00_0000_0100</td></tr>
<tr><td>0b1_0011</td>  <td>0b00_0000_0100</td></tr>

<tr><td>0b1_0100</td>  <td>0b00_1000_1000</td></tr>
<tr><td>0b1_0101</td>  <td>0b00_0000_1000</td></tr>
<tr><td>0b1_0110</td>  <td>0b00_0000_0010</td></tr>
<tr><td>0b1_0111</td>  <td>0b00_0000_0000</td></tr>

<tr><td>0b1_1000</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b1_1001</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b1_1010</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b1_1011</td>  <td>0b00_0010_0000</td></tr>

<tr><td>0b1_1100</td>  <td>0b00_0000_0000</td></tr>
<tr><td>0b1_1101</td>  <td>0b00_0000_0001</td></tr>
<tr><td>0b1_1110</td>  <td>0b11_0001_0000</td></tr>
<tr><td>0b1_1111</td>  <td>0b00_0001_0000</td></tr>
</tbody>
</table>

As we can see, a number of inputs result in zero state outputs, and the MSB
only changes the output of two ROM entries depending on whether its set or
not. Perhaps a number of these states are illegal and just given a default
output? I wonder what this ROM is used for? When I figure it out, I'll make
an edit to this page!

## Future Direction
As readers can probably see by now, digitizing and REing old ICs is
completely doable, if tedious. Personally, I would say it's more mechanical
than reversing a binary with IDA or radare2, once you know what to look for.
However, like REing a binary, it does take a long time to fully RE an IC.

There are tools to automate the schematic capture process of an IC, and aid
in analysis as well. Olivier Galibert's [dietools](https://github.com/galibert/dietools)
are one example that I hope to discuss in future posts.

_As of writing this post (October 12, 2016), my work in vectorizing and
schematic capture of the YM2151 can be found [here](https://github.com/cr1901/ym2151-decap)._

### Anecdote
Back in 2011, I discovered that the MAME project was decapping ICs to defeat
security/protection circuits on old arcade boards that prevented them from
being emulated properly. The me in 2011 thought this was the most
fascinating thing, the "last bastion" of proper accurate emulation. I never
thought I would have the skill set required to do IC analysis.

Even up until summer 2016, I said that I wouldn't do IC reverse engineering,
despite preservation of old technology being important to me. I felt it was
beyond my comprehension, and that I would not be able to learn how to
identify features in a reasonable amount of time. With help from others, I
was wrong, and I'm glad that I was. If you're on the fence about
learning a new technical subject, don't hesitate. We're all smart, and filled
with doubt. Others will be willing to help!

### Thanks
I would like to thank members of siliconpr0n for looking over this post,
especially Olivier Galibert for correcting a few mistakes. Additionally, I'd
like to thank Digi-Key for their extremely useful [Scheme-it](http://www.digikey.com/schemeit/)
schematic program, which I used to create the schematics (including the nice
arrow!).
