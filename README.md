# Musdb.jl
Julia interface to musdb, a signal separation challenge

## Musdb

This is a Julia wrapper around the python [Musdb](https://github.com/sigsep/sigsep-mus-db) interface to the [musdb18](https://sigsep.github.io/musdb) music separation challenge dataset.

## Goal

Really, to play around in Julia a bit.  I was amazed that an Ideal Bitmask can reproduce individual instruments from the mix so well from a demo.

## Prerequisites

You should have instaled the [python package](https://github.com/sigsep/sigsep-mus-db) mentioned above.

You should also download the musdb18 dataset to a local disk.

For playback, this package uses [`PortAudio`](https://github.com/JuliaAudio/PortAudio.jl).
It further uses `PyCall` to wrap the python interface and `DSP` for a default implementation of the short time Fourier transform.

## Install

```julia
Pkg.clone("https://github.com/davidavdav/Musdb.jl")
```

## Synopsys

```julia
## load the module, and name it `m` for short
m = include("src/Musdb.jl")
m.setdefaultplaybackdevice()
## load the musdn18 dataset
mus = m.DB("/path/to/audio/data")
## load tracks via PyCall
tracks = mus[:load_mus_tracks]()
## load a particular track as a `stems` structure
s = m.stem(tracks[50])
## play a particular channel
m.play(s[:vocals])
## compute an ideal bitmask
ibm = m.IBM(s)
## play signal reconstructed using the amplitude from a channel, and phase from the mixed channel
m.play(ibm, :vocals, false) ## takes a while before vocals tune in...
## the same, but use mask found in computing `ibm`
m.play(ibm, :vocals)
```

## Results so far

I can't get the extracted channels from the mix sound so well as in the demo.  It is quite rough on the edges.  I've tried a median filter over the bitmask in time, but that dodn't seem to help.
