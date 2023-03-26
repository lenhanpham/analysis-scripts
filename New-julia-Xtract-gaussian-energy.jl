#!/bin/sh
#=
module load Julia/1.6.1-linux-x86_64 
exec julia -O3 "$0" -- $@
=#


using Printf

@time begin

    extractedData = Vector{Vector{Any}}()

    # function for data extraction
    function extract(file_name)
        fileNameVec = Vector{Any}()

        # read entire file
        file_lines = readlines(file_name)

        # find last SCF Done line
        scf_index = findlast(x -> occursin("SCF Done", x), file_lines)
        zpe_index = findlast(x -> occursin("Zero-point correction", x), file_lines)
        tcg_index = findlast(x -> occursin("Thermal correction to Gibbs Free Energy", x), file_lines)
        etg_index = findlast(x -> occursin("Sum of electronic and thermal Free Energies", x), file_lines)
        ezpe_index = findlast(x -> occursin("Sum of electronic and zero-point Energies", x), file_lines)
        lf_index = findfirst(x -> occursin("Frequencies", x), file_lines)
        scrf_index = findfirst(x -> occursin("scrf", x), file_lines)
        status_index = findlast(x -> occursin("Normal", x) || occursin("Error", x), file_lines)
        error_index = findlast(x -> occursin("Error termination", x), file_lines)

        if !isnothing(scf_index)
            scf = parse(Float64, split(file_lines[scf_index])[5])
        else
            scf = 0
        end

        if !isnothing(zpe_index)
            zpe = parse(Float64, split(file_lines[zpe_index])[3])
        else
            zpe = 0
        end

        if !isnothing(tcg_index)
            tcg = parse(Float64, split(file_lines[tcg_index])[7])
        else
            tcg = 0
        end

        if !isnothing(etg_index)
            etg = parse(Float64, split(file_lines[etg_index])[8])
        else
            etg = 0
        end

        if !isnothing(ezpe_index)
            ezpe = parse(Float64, split(file_lines[ezpe_index])[7])
        else
            ezpe = 0
        end

        if !isnothing(lf_index)
            lf = parse(Float64, split(file_lines[lf_index])[3])
        else
            lf = 0
        end

        phaseCorr = "NO"
        if isnothing(scrf_index)
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
        if !isnothing(status_index)
            n = split(file_lines[status_index])[1]
        end

        if !isnothing(error_index)
            status = "Error"
        elseif n == "Normal"
            status = "Done"
        else
            status = "undone"
        end
        fileNameVec = [file_name, etgkj, lf, GibbsFreeHartree, etg, etgev, scf, zpe, status, phaseCorr]
        return fileNameVec
    end



    function printheader()
        println("                       Output name      ETG kJ/mol       Low FC      ETG a.u     ETG noCorr a.u     ETG eV           SCFE      ZPE    Status   PCorr")
        println("                       -----------      ----------       ------      -------         ------          ------          ----      ----   ------   ----")
    end

    function extractE()
        files = filter(x -> occursin(".log", x), readdir())
        extractedDataLock = ReentrantLock() 
        Threads.@threads for file_name in files
            fileData = extract(file_name)
            lock(extractedDataLock)
            try 
                push!(extractedData, fileData)
            finally
                unlock(extractedDataLock)
            end
        end 
        return extractedData
    end

 
    printheader()
    extractE()
    sort!(extractedData, by=x -> x[2])

    for row in extractedData
        #print out deserved information
        formatted_row = [lpad(row[1], 35), lpad(string(@sprintf("%.2f", row[2])), 15), lpad(string(@sprintf("%.2f", row[3])), 10), lpad(string(@sprintf("%.5f", row[4])), 15), lpad(string(@sprintf("%.5f", row[5])), 15), lpad(string(@sprintf("%.5f", row[6])), 15), lpad(string(@sprintf("%.5f", row[7])), 13), lpad(string(@sprintf("%.2f", row[8])), 6), lpad(row[9], 8), lpad(row[10], 6)]
        println(join(formatted_row, " "))
    end

end

