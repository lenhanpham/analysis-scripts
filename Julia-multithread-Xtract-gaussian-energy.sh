module load julia

### copy julia-Xtract-gaussian-energy.jl to your bin and chmod 750
### change value to increase the number of threads. Here the default value is 4. 

julia -t 4 ~/bin/julia-Xtract-gaussian-energy.jl | tee $(basename $(pwd)).results 