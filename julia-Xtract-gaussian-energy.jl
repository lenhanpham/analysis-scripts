#!/bin/sh
#=
module load julia 
exec julia -O3 "$0" -- $@
=#

using Statistics
using CSV
using NamedArrays
using Printf

extractedData = Vector{Vector{Any}}()

# function for data extraction
function extract(file_name)
    fileNameVec = Vector{Any}()

    # read entire file
    file_lines = readlines(file_name)

    # find last SCF Done line
    scf = 0
    try
        scf = parse(Float64, split(file_lines[findlast(x -> occursin("SCF Done", x), file_lines)])[5])
    catch

    end

    # find last Zero-point correction line
    zpe = 0
    try
        zpe = parse(Float64, split(file_lines[findlast(x -> occursin("Zero-point correction", x), file_lines)])[3])
    catch

    end

    # find last Thermal correction to Gibbs Free Energy line
    tcg = 0
    try
        tcg = parse(Float64, split(file_lines[findlast(x -> occursin("Thermal correction to Gibbs Free Energy", x), file_lines)])[7])
    catch

    end

    # find last Sum of electronic and thermal Free Energies line
    etg = 0
    try
        etg = parse(Float64, split(file_lines[findlast(x -> occursin("Sum of electronic and thermal Free Energies", x), file_lines)])[8])
    catch

    end

    # find last Sum of electronic and zero-point Energies line
    ezpe = 0
    try
        ezpe = parse(Float64, split(file_lines[findlast(x -> occursin("Sum of electronic and zero-point Energies", x), file_lines)])[7])
    catch

    end

    # find first Frequencies line
    lf = 0
    try
        lf = parse(Float64, split(file_lines[findfirst(x -> occursin("Frequencies", x), file_lines)])[3])
    catch

    end

    phaseCorr = "NO"
    scrf = findfirst(x -> occursin("scrf", x), file_lines)
    if isnothing(scrf)
        GibbsFreeHartree = etg
        phaseCorr = "NO"
    else
        GibbsFreeHartree = etg + 0.003031803235
        phaseCorr = "YES"
    end

    etgev = GibbsFreeHartree * 27.211396641308
    etgkj = GibbsFreeHartree * 2625.5002

    # check status of output
    n = "unknown"
    m = "unknown"
    try
        n = split(file_lines[findlast(x -> occursin("Normal", x) || occursin("Error", x), file_lines)])[1]
        m = split(file_lines[findlast(x -> occursin("termination", x), file_lines)])[2]
    catch

    end
    if n == "Normal" 
        status = "Done"
    elseif n == "Error" && m == "termination"
        status = "Error"
    else
        status = "undone"
    end


    fileNameVec = [file_name, etgkj, lf, GibbsFreeHartree, etg, etgev, scf, zpe, status, phaseCorr]
    return fileNameVec
end

function printheader()
    println("                   Output name          ETG kJ/mol       Low FC      ETG a.u     ETG noCorr a.u     ETG eV           SCFE      ZPE    Status   PCorr")
    println("                   -----------          ----------       ------      -------         ------          ------          ----      ----   ------   ----")
end



function extractE()
    files = filter(x -> occursin(".log", x), readdir())
    for file_name in files
        fileData = extract(file_name)
        push!(extractedData, fileData)
        sort!(extractedData, by=x -> x[2])
    end
    return extractedData
end

printheader()
extractE()

for row in extractedData
    #print out deserved information
    formatted_row = [lpad(row[1], 35), lpad(string(@sprintf("%.2f", row[2])), 15), lpad(string(@sprintf("%.2f", row[3])), 10), lpad(string(@sprintf("%.5f", row[4])), 15), lpad(string(@sprintf("%.5f", row[5])), 15), lpad(string(@sprintf("%.5f", row[6])), 15), lpad(string(@sprintf("%.5f", row[7])), 13  ), lpad(string(@sprintf("%.2f", row[8])), 6), lpad(row[9], 8), lpad(row[10], 6)]
    println(join(formatted_row, " "))

end

