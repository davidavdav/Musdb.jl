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
# m = include("src/Musdb.jl")
import Musdb
m = Musdb 
# m.setdefaultplaybackdevice()
## load the musdb18 dataset
mus = m.DB("/path/to/audio/data")
## load tracks via PyCall
tracks = m.load_mus_tracks(mus)
## load a particular track as a `stems` structure
s = m.stems(tracks[50])
## play a particular channel
m.play(s[:vocals]) ## it takes a while before vocals tune in...
## compute an ideal bitmask
ibm = m.IBM(s)
## play signal reconstructed using the amplitude and phase from the target channel, this should be perfect
m.play(ibm, :vocals, false)
## the same, but use mask found in computing `ibm`, and the signal from :mixed
m.play(ibm, :vocals)
## compute Ideal Ratio Mask
irm = m.IRM(m.stems(tracks[1]))
m.play(irm, :vocals)
```

## Results so far

It seems we can reconstruct the audio signal fairly well from the `stft` with `istft`, and the IBM and  IRM masks work OK, although reconstruction shows some artifacts here and there.
