using Statistics
using CSV
#using NamedArrays

### This snipper of Julia code was written by Le Nhan Pham (https://lenhanpham.github.io/) 
### and is experimenting. Some of functions are not working well
### This snippet of Julia code is used to extract energy from gaussian outputs with thermal correction, phase correction if solvent is used. 
### Total Gibbs free energies will be sorted with the mostable structures on the top. 
### Todo list: write output to a file. 

extractedData = Vector{Vector{Any}}() 

# function for data extraction
function extract(file_name)
    fileNameVec = Vector{Any}() 

    scf = 000000
    try
    scf = parse(Float64, split(readlines(file_name)[findlast(x -> occursin("SCF Done", x), readlines(file_name))])[5])
    #println(scf)
    catch
    
    end

    zpe = 000000 
    try
    zpe = parse(Float64, split(readlines(file_name)[findlast(x -> occursin("Zero-point correction", x), readlines(file_name))])[3])
    #println(zpe)
    catch

    end

    tcg = 000000 
    try
    tcg = parse(Float64, split(readlines(file_name)[findlast(x -> occursin("Thermal correction to Gibbs Free Energy", x), readlines(file_name))])[7])       
    #println(tcg)
    catch
    
    end


    etg = 000000 
    try
        etg = parse(Float64, split(readlines(file_name)[findlast(x -> occursin("Sum of electronic and thermal Free Energies", x), readlines(file_name))])[8])    
    #println(etg)
    catch
    
    end


    ezpe = 000000 
    try
        ezpe = parse(Float64, split(readlines(file_name)[findlast(x -> occursin("Sum of electronic and zero-point Energies", x), readlines(file_name))])[7])
    #println(ezpe)
    catch
    
    end


    lf = 000000 
    try
        lf = parse(Float64, split(readlines(file_name)[findfirst(x -> occursin("Frequencies", x), readlines(file_name))])[3])
    #println(lf)
    catch
    
    end

    phaseCorr = 0
    scrf = "no"
    try
    scrf = readlines(file_name)[findfirst(x -> occursin("scrf", x), readlines(file_name))]
    #println(scrf)
    catch
        println("Gas phase")
    end   
    if scrf == "no"
        GibbsFreeHartree = etg
        phaseCorr = "NO"

    else
        GibbsFreeHartree = etg + 0.003031803235
        phaseCorr = "YES"

    end
    
    etgev = GibbsFreeHartree * 27.211396641308
    etgkj = GibbsFreeHartree * 2625.5002

    
    # check status of output
    n = "unknow"
    try
        n = split(readlines(file_name)[findlast(x -> occursin("Normal", x) || occursin("Error", x), readlines(file_name))])[1]
    catch 
    
    end 
    if n == "Normal"
        status = "Done"
    elseif n == "Error"
        status ="Error"
    else
        status = "Undone" 
    end


    
    append!(fileNameVec, [file_name, etgkj, lf, GibbsFreeHartree, etg, etgev, scf, zpe, status, phaseCorr])
    return fileNameVec
end

function prinheader()
    println("Output name                               ETG kJ/mol            Low FC          ETG a.u          ETG noCorr a.u         ETG eV                  SCFE             ZPE      Status   PCorr")
    println("-----------                               ----------            ------          -------               ------            ------                  ----             ----     ------   ----")
end



function extractE()
    files = filter(x -> occursin(".log", x), readdir())
    for file_name in files
        fileData = extract(file_name)
        push!(extractedData, fileData) 
        sort!(extractedData, by = x -> x[2])
    end
    return extractedData
end


   
prinheader()
extractE()

for row in extractedData
    #println(row)
    #print out deserved information
    println("$(lpad(string(row[1]), 35)) $(lpad(row[2], 25)) $(lpad(row[3], 10)) $(lpad(string(row[4]), 22)) $(lpad(string(row[5]), 15)) $(lpad(string(row[6]), 25)) $(lpad(string(row[7]), 18)) $(lpad(string(row[8]), 10)) $(lpad(row[9], 8)) $(lpad(row[10], 6))")
end

