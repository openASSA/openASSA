#output::::
#policy_values : [-100543.82048490716, -342872.4313366279, -767286.5575382583, -240554.77718724162]
#done
#counter : 5.0
#  0.667037 seconds (1.11 M allocations: 52.117 MiB, 0.90% gc time)

import Base.Threads.@spawn
import Pkg
Pkg.add("XLSX")
using XLSX
PROJECTION = 2140

#using BenchmarkTools

include("./resources/custom_functions.jl")

function get_value(colname, proj, policy, mortality, lapse, yieldc, model, prev_model)
    s = Symbol(colname)
    f = getfield(Main, s)
    return f(proj, policy, mortality, lapse, yieldc, model, prev_model)
end

function get_model(policy_values, policies, mortality, lapse, yieldc)
    counter = 1.0
    col_names = ["projection", "age", "duration", "mort", "lapserate", "yieldcurve",
    "deaths", "surrenders", "activepol", "premincome", "claimsoutgo", "profit", "presentval"]
    empty_row = zeros(Float64, length(col_names))
    prev_model = empty_row
    curr_model = empty_row
    projection_range = StepRange(1, 1, PROJECTION)
    for policy in eachrow(policies)
        for proj in projection_range
            prev_model = curr_model
            curr_model = empty_row
            curr_model[1] = projection(proj)
            curr_model[2] = age(proj, policy)
            curr_model[3] = duration(proj,policy)
            curr_model[4] = mort(proj, policy, mortality, prev_model)
            curr_model[5] = lapserate(proj, policy, lapse, prev_model)
            curr_model[6] = yieldcurve(proj, yieldc, prev_model)
            curr_model[7] = deaths(curr_model)
            curr_model[8] = surrenders(curr_model)
            curr_model[9] = activepol(proj, curr_model, prev_model)
            curr_model[10] = premincome(policy, curr_model)
            curr_model[11] = claimsoutgo(policy, curr_model)
            curr_model[12] = profit(curr_model)
            curr_model[13] = presentval(proj, curr_model)
            policy_values[policy[1]] += curr_model[13]
        end
        counter = counter + 1
    end
    println("counter : ", counter)
    return policy_values
end

function readExcelSheet(filename, sheet_name)
    excelsheet = XLSX.readtable(filename, sheet_name)[1]
    len = length(excelsheet)
    wth = length(excelsheet[1])
    return policies = reshape(collect(Iterators.flatten(excelsheet)),(wth,len))
end

function main()
    #filepath = "openASSA/POC1_Lavesh"
    filename = "Simple Life Model_Julia.xlsm"
    #filename = joinpath(filepath, filename)

    mortality = []
    lapse = []
    yieldc = []
    policies = []
    all_sheets = XLSX.readxlsx(filename)
    sheet_names = XLSX.sheetnames(all_sheets)
    for sheet_name in sheet_names
        if ! (lowercase(sheet_name) in ["info", "results", "model"])
            if occursin("mortality", lowercase(sheet_name))
                mortality =  readExcelSheet(filename, sheet_name)
            elseif occursin("lapse", lowercase(sheet_name))
                lapse =  readExcelSheet(filename, sheet_name)
            elseif occursin("yield", lowercase(sheet_name))
                yieldc =  readExcelSheet(filename, sheet_name)
            elseif occursin("policy", lowercase(sheet_name))
                policies =  readExcelSheet(filename, sheet_name)
            end
        end
    end
    policy_values = zeros(Float64, size(policies)[1])
    #@time @spawn
    get_model(policy_values, policies, mortality, lapse, yieldc)
    println("policy_values : ", policy_values)
end

main()
println("done")
