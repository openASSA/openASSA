function read_functionname(line)
    startpos = length(findfirst("function ", line))
    endpos = findfirst("(", line)[1]
    return SubString(line, startpos + 1, endpos - 1)
end

mkpath("./resources/")
cd("./resources/")
println("current path is : ", pwd())
touch("custom_functions.jl")

function_names =  String[]

open("custom_functions.jl", "r") do io
    # line_number
    fcount = 0
    # read till end of file
    while ! eof(io)
        # read a new / next line for every iteration
        line = readline(io)
        if string(findfirst("function ", line)) == "1:9"
            push!(function_names, (read_functionname(line)))
            fcount += 1
        end
    end
end

println(function_names)

open("custom_functions.jl", "a") do io
    if !("duration" in function_names)
        println(io, "#\$B\$4+A12")
        println(io, """
        function duration(proj, policy)
            return policy[5] + proj
        end   
        """)
    end

    if !("projection" in function_names)
        println(io, """
        function projection(proj)
            return proj
        end  
        """)
    end

    if !("age" in function_names)
        println(io, "#INT(\$B\$3+A12/12)")
        println(io, """
        function age(proj, policy)
            return trunc(Int, policy[2] + trunc(Int, proj/12))
        end    
        """)
    end

    if !("mort" in function_names)
        println(io, """
        function mort(proj, policy, mortality, prev_model)
            try
                idx = trunc(Int, policy[2] + trunc(Int, proj/12))
                return mortality[idx, 2]
            catch
                return prev_model[4]
            end
        end
        """)
    end

    if !("lapserate" in function_names)
        println(io, """
        #IF(INT((C12-1)/12)+1>'Lapse Table'!\$A\$11,E11,VLOOKUP(INT((C12-1)/12)+1,'Lapse Table'!\$A\$2:\$B\$11,2,FALSE))/12
        function lapserate(proj, policy, lapse, prev_model)
            try
                idx = trunc(Int, trunc(Int, policy[5] + proj - 1)/12) + 1
                return lapse[idx, 2]/12
            catch
                try
                    return prev_model[5]
                catch
                    return 0
                end
            end
        end
        """)
    end

    if !("yieldcurve" in function_names)
        println(io, """
        #IF(A12>'Yield Curve'!A626,L11,(1+VLOOKUP(A12,'Yield Curve'!A5:B627,2,FALSE))^(1/12)-1)
        function yieldcurve(proj, yieldc, prev_model)
            try
                return ((yieldc[round(proj), 2] + 1)^(1/12))-1
            catch
                try
                    return prev_model[6]
                catch
                    return 0
                end
            end
        end
        """)
    end

    if !("deaths" in function_names)
        println(io, """
        #D12/12*(1-0.5*E12)
        function deaths(model)
            return model[4]/12 * (1-0.5*model[5])
        end
        """)
    end

    if !("surrenders" in function_names)
        println(io, """
        #E12*(1-0.5*D12)
        function surrenders(model)
            return (1-0.5*model[4]) * (model[5])
        end
        """)
    end

    if !("activepol" in function_names)
        println(io, """
        #F11-G12-H12
        function activepol(proj, model, prev_model)
            try
                if proj == 1
                    return 1 - model[7] - model[8]
                else
                    return prev_model[9] - model[7] - model[8]
                end
            catch
                return 1 - model[7] - model[8]
            end
        end
        """)
    end

    if !("premincome" in function_names)
        println(io, """
        #F12*\$B\$5/12
        function premincome(policy, model)
            return policy[3] * model[9]/12
        end
        """)
    end

    if !("claimsoutgo" in function_names)
        println(io, """
        #\$B\$6*G12
        function claimsoutgo(policy, model)
            return policy[4] * model[7]
        end
        """)
    end

    if !("profit" in function_names)
        println(io, """
        #I12-J12
        function profit(model)
            return model[10] - model[11]
        end
        """)
    end

    if !("presentval" in function_names)
        println(io, """
        #K12*(1+L12)^-A12
        function presentval(proj, model)
            return model[12] * (1 + model[6]) ^ (-1 *proj)
        end
        """)
    end
end