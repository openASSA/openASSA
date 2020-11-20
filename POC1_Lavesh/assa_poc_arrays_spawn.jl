#output::::
#policy_values : [-100543.82048490716, -342872.4313366279, -767286.5575382583, -240554.77718724162]
#done
#counter : 5.0
#  0.667037 seconds (1.11 M allocations: 52.117 MiB, 0.90% gc time)

import Base.Threads.@spawn
import XLSX
using XLSX
PROJECTION = 2140

function projection(proj)
    return proj
end

#INT($B$3+A12/12)
function age(proj, policy)
    return trunc(Int, policy[2] + trunc(Int, proj/12))
end

#$B$4+A12
function duration(proj, policy)
    return policy[5] + proj
end

function mort(proj, policy, mortality, prev_model)
    try
        idx = trunc(Int, policy[2] + trunc(Int, proj/12))
        return mortality[idx, 2]
    catch
        return prev_model[4]
    end
end

#IF(INT((C12-1)/12)+1>'Lapse Table'!$A$11,E11,VLOOKUP(INT((C12-1)/12)+1,'Lapse Table'!$A$2:$B$11,2,FALSE))/12
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

#D12/12*(1-0.5*E12)
function deaths(model)
    return model[4]/12 * (1-0.5*model[5])
end

#E12*(1-0.5*D12)
function surrenders(model)
    return (1-0.5*model[4]) * (model[5])
end

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

#F12*$B$5/12
function premincome(policy, model)
    return policy[3] * model[9]/12
end

#$B$6*G12
function claimsoutgo(policy, model)
    return policy[4] * model[7]
end

#I12-J12
function profit(model)
    return model[10] - model[11]
end

#K12*(1+L12)^-A12
function presentval(proj, model)
    return model[12] * (1 + model[6]) ^ (-1 *proj)
end

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
            curr_model[3] = duration(proj, policy)
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
    filepath = "C:/Users/saa2005/github/openASSA/POC1_Lavesh"
    filename = "Simple Life Model_Julia.xlsm"
    filename = joinpath(filepath, filename)

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
    policy_values = @spawn @time get_model(policy_values, policies, mortality, lapse, yieldc)
    println("policy_values : ", policy_values)
end

main()
println("done")
