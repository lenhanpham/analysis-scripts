# Scripts for analysis of outputs or creation of inputs
Several scripts used to analyze outputs of quantum chemical calculations or generate inputs are deposited here. Most of them are bash scripts because bash scripts are easy and fast to write. A couple of them were written in Python or Julia depending on the importance of performance. 

I still do not have time to write manual of how to use them. If you need to use something, just leave comments in the issue space. I'll explain.

For the julia gaussian extraction script (New-julia-Xtract-gaussian-energy.jl), if you want to use it in parallel to improve the performance when you have large amounts of outputs, copy the Julia-multithread-Xtract-gaussian-energy.sh and New-julia-Xtract-gaussian-energy.jl to your bin, and chmod 750 for all before using them by typing Julia-multithread-Xtract-gaussian-energy.sh in the dir where your Gaussian log files located.
