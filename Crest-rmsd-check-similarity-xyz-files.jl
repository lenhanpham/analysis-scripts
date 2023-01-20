using Pipe
using Printf
#using Commands


# To use this script, a list of xyz files without extension (xyz) must be provided. Can use ls *.xyz to create this list and name it as "round-0.list".
#Or this list can be obtained from the XTB-extract-energy.shell script. With this list, energy is ranked, and all xyz files are ranked energetically.

# Set environment to let Julia know crest
ENV["PATH"] = "$(ENV["PATH"]):/home/595/np9048/sources/xtb/xtb-6.5.0/bin"


function crest(file1::String, file2::String)
    result = 0.0
    crestOutText = `crest --rmsd $(file1) $(file2)`
    run(crestOutText)
    crestOutput = []
    open(crestOutText, "r", stdout) do io
        i = 0
        for ln in readlines(io)
            i += 1
            push!(crestOutput, ln)
        end
    end
    lastline = split(crestOutput[end])
    result = parse(Float64, lastline[end])
    return result
end


done_file = basename(pwd()) * "-done.txt"
similar_file = "similar.txt"

if isfile(done_file)
    rm(done_file)
end

if isfile(similar_file)
    rm(similar_file)
end

l = 0

firstlistxyz = readlines(open(@sprintf("round-%d.list", l)))
n = length(firstlistxyz)
println("Initial number of structures: ", n)

for i in 0:n-1
    listxyz = readlines(open(@sprintf("round-%d.list", l)))
    m = length(listxyz)
    if m == 0
        m = 0
    end
    if m == 0
        break
    end
    println("Round ", l)
    println("number of remaining structures: ", m)
    global l += 1
    if isfile(@sprintf("round-%d.list", l))
        rm(@sprintf("round-%d.list", l))
    else
        break
    end
    k = 1
    firstfile = strip(chomp(listxyz[k]))
    open(done_file, "a") do f
        write(f, "$firstfile\n")
    end
    for j in 1:m-1
        secondfile = strip(chomp(listxyz[j]))
        rmsd = crest("$firstfile.xyz", "$secondfile.xyz")
        println("$firstfile.xyz $secondfile.xyz rmsd: $rmsd")
        if rmsd >= 0.3
            open(@sprintf("round-%d.list", l), "a") do f
                write(f, "$secondfile\n")
            end
        else
            open(similar_file, "a") do f
                write(f, "$secondfile rmsd: $rmsd\n")
            end
        end
    end
    listxyz = []
end

