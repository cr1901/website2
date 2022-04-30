+++
title = "Floppy Disk Notes"
description = "A compilation on literature discussing the theory of operation of floppy disk drives."
date = 2016-02-10
updated = 2022-04-30
aliases = ["blog/floppy-lit.html"]
+++

# Floppy Disk Notes
What follows is a set of links that I've collected over the years that
give technical information on how to encode/decode floppy disks signals, as
well as the theory of operation behind this dying medium.

I find reading these documents important for preservation purposes,
especially since computer programmers of the past relied on these engineering
details for copy protection purposes.

Additionally, a deep understanding of internals may one day help to recover
data that is thought to be lost using statistical analysis of the read signal.

Links are ordered relatively in the order I read them/I recommend reading
them, and sections tend to build upon each other.

## General
<dl>
{% linkcont(name="The Floppy User Guide", url="http://www.hermannseib.com/documents/floppy.pdf") %}
A good technical overall technical description of how a floppy drive accesses
data.
{% end %}
</dl>

## Floppy Drive
<dl>
{% linkcont(name="SA800/801 Diskette Storage Drive Theory of Operations", url="http://www.mirrorservice.org/sites/www.bitsavers.org/pdf/shugart/SA8xx/50664-0_SA800_801_Theory_of_Operations_Apr76.pdf") %}
Without question, the most important document on this list.
If you read any document, read this. It's not quite enough information
to build a floppy drive from scratch, but it's enough to bring someone
interested up to speed. Hard to believe this document is 40 years old in 2016!
{% end %}

{% linkcont(name="SA850/SA450 Read Channel Analysis Internal Memo", url="http://www.mirrorservice.org/sites/www.bitsavers.org/pdf/shugart/_specs/SA850_450_Read_Channel_Analysis_Dec79.pdf") %}
This internal memo donated by a Shugart employee includes a
floppy drive read head transfer function analysis based on experiments
Shugart did in the late 70's.
{% end %}
</dl>

## Phase-Locked Loops (PLLs)
<dl>
{% linkcont(name="Phaselock Techniques, Floyd M. Gardner", url="http://www.fulviofrisone.com/attachments/article/466/Phaselock%20Techniques%20(Gardner-2005).pdf") %}
A monograph on analog PLLs. Does not discuss All-Digital PLLs (ADPLLs).
{% end %}

{% linkcont(name="NXP Phase Locked Loops Design Fundamentals Application Note", url="https://www.nxp.com/files-static/rf_if/doc/app_note/AN535.pdf") %}
A quick reference for analog PLL design.
{% end %}
</dl>

## Encodings
<h3><abbr title="Modified Frequency Modulation">MFM</abbr></h3>
<dl>
{% linkcont(name="Floppy Disk Data Separator Design Guide for the DP8473", url="http://www.bitsavers.org/components/national/_dataSheets/DP8473/AN-505_Floppy_Disk_Data_Separator_Design_Guide_for_the_DP8473_Feb89.pdf") %}
To be written.
{% end %}

{% linkcont(name="Encoding/Decoding Techniques Double Floppy Disc Capacity", url="http://bitsavers.informatik.uni-stuttgart.de/magazines/Computer_Design/198002_Encoding-Decoding_Techniques_Double_Floppy_Disc_Capacity.pdf") %}
Gives background on more complicated physical phenomenon associated with floppy drive recording, such as magnetic domain shifting.
{% end %}

{% linkcont(name="Floppy Data Extractor", url="http://web.archive.org/web/20150212042616/http://www.analog-innovations.com/SED/FloppyDataExtractor.pdf") %}
A schematic for a minimum component data separator that does not require a
PLL, but uses a digital equivalent. Perhaps a simple <abbr title="All Digital
Phase-Locked Loop">ADPLL</abbr>?
{% end %}
</dl>

<h3><abbr title="Run-Length Limited">RLL</abbr></h3>
<dl>
{% linkcont(name="IBM's Patent for (1,8)/(2,7) RLL", url="http://www.google.com/patents/US3689899") %}
I'm not aware of any floppy formats that use (2,7) RLL, but hard drives
that descend from MFM floppy drive encodings do use RLL. RLL decoding is far
more involved than FM/MFM.
{% end %}
</dl>

<h3><abbr title="Group Code Recording">GCR</abbr></h3>
This is a format used by Apple II drives and descendants. Software has
more control over this format, so there are more opportunities for
elaborate data protection compared to the IBM platforms. TODO when I have
time to examine non-IBM formats.

## Track Formats
### IBM 3740 (FM, Single Density)
TODO. Described in Shugart's Theory of Operations manual.

### IBM System 34 (MFM, Double Density)
TODO. Described in various documents on this page, but I've not yet found
a document dedicated to explaining the format.

## Floppy Disk Controller ICs
### NEC 765
<dl>
{% linkcont(name="765 Datasheet", url="http://www.classiccmp.org/dunfield/r/765.pdf") %}
The FDC used in IBM PCs. It is not capable of writing raw data at the level
of the IBM track formats. Thus, attempting to write copy-protected floppies
is likely to fail with this controller.
{% end %}

{% linkcont(name="765 Application Note", url="https://archive.org/details/bitsavers_necdatashe79_1461697") %}
NEC created an application note to discuss how to integrate the 765 into a
"new" system, either using DMA or polling on receipt of interrupts.
{% end %}
</dl>

### TI TMS279X</h3>
<dl>
{% linkcont(name="TMS279X Datasheet", url="http://info-coach.fr/atari/documents/general/fd/TMS279X_DataSheet.pdf") %}
Includes a diagram of the IBM System 34 track format.
{% end %}
</dl>

<h3>NI DP8473</h3>
<dl>
{% linkcont(name="DP8473 Datasheet", url="DS009384.PDF") %}
A successor to the 765 that is capable of handing formats such as 1.2MB High
Density (HD) disks
{% end %}

{% linkcont(name="Design Guide for DP8473 in a PC-AT", url="http://www.bitsavers.org/components/national/_dataSheets/DP8473/AN-631_Design_Guide_for_DP8473_in_a_PC-AT_Dec89.pdf") %}
TODO. It appears I lost my original commentary on this document.
{% end %}
</dl>

## Floppy Disk Controller Cards
<dl>
{% linkcont(name="IBM PC FDC Card (765)", url="http://www.minuszerodegrees.net/oa/OA%20-%20IBM%205.25%20Diskette%20Drive%20Adapter.pdf") %}
Includes schematics. The PLL circuit on the last page is in particular worth
analyzing.
{% end %}
</dl>

If anyone has any interesting new documents to add, please feel free
to contact me, and I will add them to this page with credit!
