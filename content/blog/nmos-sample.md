+++
title = "NMOS IC Reverse Engineering"
description = "The first in a series of posts about how to analyze (old!) silicon die images and extract transistors to study the underlying circuit."
date = 2016-10-12
aliases = ["blog/nmos-sample.html"]
+++

Recently, I was <del>tricked</del> <ins>talked</ins> into examining the die of
an integrated circuit (IC)- the YM2151, a single-chip FM synthesizer. I like
these old Yamaha chips, so I don't really mind doing it, but it's definitely
a long term project that I expect to take months. However, one doesn't need to
RE a significant portion of an IC to understand the basics of RE. Information
about a chip's operation can be gleamed by examining small units,
and predicting their relation to each other.

Information on doing IC reverse-engineering is still kind of limited, although projects like
[siliconpr0n](https://siliconpr0n.org) and whatever [Ken Shirrif](http://www.righto.com/2014/10/how-z80s-registers-are-implemented-down.html)
is working on at any given time are changing that. Since I am learning how to RE ICs, I decided to
document how I decoded a small ROM in the YM2151 that I <em>suspect</em> is
being used as part of the control state machine. This small ROM demonstrates
the basics of REing ICs, including:

* Separating the various layers of an IC die.
* Mapping ROM inputs and outputs.
* Manually reading out the ROM contents.

# Obtaining a Die Image

Before we can examine an IC die, we have to actually digitally capture an image
of the die. I will not be discussing this in detail, but getting a die image typically involves:

* Removing the IC package with corrosive chemicals, called decap.
* Taking a number of pictures using a digital camera with a microscope.
* Stitching all the individual images together to produce a full map of the IC die with individual transistors visible.

I really don't have access to the equipment to do this even at a small scale,
but luckily this work was done previously in the case of YM2151 (20x magnification).
I defer to Travis Goodspeed's article in section 9 of [POC||GTFO #4](https://archive.org/details/pocorgtfo04))
if interested in doing decap yourself.

![YM2151 die image](ym2151_die.png)
Die image of YM2151 at 20x magnification, full die. The full-size
image is 617MB ([Source](https://siliconpr0n.org/map/yamaha/ym2151/mz_mit20x)).

<!-- {% figure(alt="YM2151 die image.", url="ym2151_die.png") %}
Die image of YM2151 at 20x magnification, full die. The full-size
image is 617MB {{ (<a href="https://siliconpr0n.org/map/yamaha/ym2151/mz_mit20x/">Source</a>) | safe }} ."))
{% end %} -->


<!-- <figure>
<img alt="{{alt}}" src="/assets/img/nmos/ym2151_die.png">
<figcaption>Die image of YM2151 at 20x magnification, full die. The full-size
image is 617MB (LINK(`https://siliconpr0n.org/map/yamaha/ym2151/mz_mit20x/', `Source')).</figcaption>
</figure> -->


<!-- ![YM2151 die image](static/img/nmos/ym2151_die.png) -->
