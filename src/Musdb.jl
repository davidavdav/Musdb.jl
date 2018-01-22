module Musdb

import PyCall
import PortAudio
using DSP

PyCall.@pyimport musdb

DB(root_dir=get(ENV, "MUSDB_PATH")) = musdb.DB(root_dir=root_dir)

## load stems from a track
function stems(o::PyCall.PyObject; slow=false)
    if slow
        d = Dict(Symbol(key) => value[:audio] for (key, value) in o[:targets])
        d[:mixed] = o[:audio]
    else
        ## read data once, return a set of views on the data
        data = o[:stems]
        sources = keys(o[:sources])
        d = Dict(Symbol(key) => view(data, o[:sources][key][:stem_id]+1, :, :) for (i, key) in enumerate(sources))
        d[:mixed] = view(data, 1, :, :)
    end
    return d
end

Nfft = 882

## DSP gives us "stft" which does most of the heavy lifting for us, we dispatch by stereo signals
## We force a hamming window because that is invertable, well, i don't know, but really read
## http://pubman.mpdl.mpg.de/pubman/item/escidoc:152164:1/component/escidoc:152163/395068.pdf
function DSP.stft(x::AbstractMatrix{T}, n=Nfft, noverlap=n ÷ 2) where T<:AbstractFloat
    y = Array{Matrix{Complex{T}}}(2)
    for chan in 1:size(x, 2)
        y[chan] = DSP.stft(x[:, chan], n, noverlap, window=hamming, onesided=false)
    end
    return cat(3, y...)
end

"""Inverse of `stft()`, the short term fourier transform"""
function istft(s::AbstractMatrix{T}, n=Nfft, noverlap=n ÷ 2) where T
    x = real(ifft(s, 1))
    nf = size(x, 2)
    ## quick hack for perfect reconstruction is noverlap = n/2
    x[1:n, :] ./= 2hamming(n)
    x[1:(n-noverlap), 1] *= 2
    x[(n-noverlap+1):n, end] *= 2
    nout = length(x) - noverlap * (nf-1)
    y = zeros(real(T), nout)
    for j in 1:nf, i in 1:n
        y[(j-1)*(n-noverlap) + i] += x[i, j]
    end
    return y
end

## The tree-dimensional case is freq x frame x channel
function istft(s::AbstractArray{T,3}) where T
    ys = [istft(s[:,:,i]) for i in 1:size(s, 3)]
    hcat(ys...)
end

# encode
polar(x::Array) = (abs.(x), angle.(x))

#decode
Base.complex(r::Array, θ::Array) = r .* exp.(im * θ)
Base.complex(t::Tuple) = complex(t...)

function IBM(stems::Dict, N=Nfft; thres=0.5, eps=1e-7)
    A, ϕ = polar(stft(stems[:mixed], N))
    d = Dict{Symbol, Tuple}()
    for key in keys(stems)
        Akey, ϕkey = polar(stft(stems[key], N))
        d[key] = tuple((Akey ./ (eps .+ A)) .> thres, Akey, ϕkey)
    end
    return d
end

## This should dispatch on an object computer by `IBM`.  Plays using phase from mixed, and
## amplitude from either
## - :mixed, using requested bitmask from `ibm`
## - the requested key
function play(ibm::Dict{Symbol, Tuple}, key::Symbol=:mixed, mask::Bool=true)
    key in keys(ibm) || error("Unknow track $key")
    if mask
        A = ibm[key][1] .* ibm[:mixed][2]
    else
        A = ibm[key][2]
    end
    play(istft(complex(A, ibm[:mixed][3])))
end

## play audio
function setdefaultplaybackdevice()
    dev = nothing
    for d in PortAudio.devices()
        if d.maxoutchans > 0
            dev = d
            break
        end
    end
    return dev
end

function setoutputdev(name::AbstractString="Display Audio")
    for d in PortAudio.devices()
        if d.name == name
            global dev = d
            return dev
        end
    end
    return nothing
end

function play(x::AbstractArray{T}, srate=44100.0) where T <: AbstractFloat
    dev == nothing && "No output audio devices found"
    nchan = ndims(x) == 1 ? 1 : size(x, 2)
    if nchan > dev.maxoutchans
        x = mean(x, 2)
        nchan = 1
    end
    stream = PortAudio.PortAudioStream(dev, 0, nchan, samplerate=srate)
    write(stream, convert(Array{Float32}, x))
    close(stream)
end

end
