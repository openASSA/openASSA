#output::::
#counter : 5.0
#  1.898799 seconds (10.32 M allocations: 802.283 MiB, 5.15% gc time)
#policy_values : [-100543.82048490716, -342872.4313366279, -767286.5575382583, -240554.77718724162]
#done

using DataFrames, XLSX
PROJECTION = 2140

function createDF(projection_range)
    model = DataFrame(projection = projection_range, age =  zeros(Float64,PROJECTION),
    duration =  zeros(Float64,PROJECTION), mort =  zeros(Float64,PROJECTION),
    lapserate =  zeros(Float64,PROJECTION), yieldcurve =  zeros(Float64,PROJECTION),
    deaths =  zeros(Float64,PROJECTION), surrenders =  zeros(Float64,PROJECTION),
    activepol =  zeros(Float64,PROJECTION), premincome =  zeros(Float64,PROJECTION),
    claimsoutgo =  zeros(Float64,PROJECTION), profit =  zeros(Float64,PROJECTION),
    presentval =  zeros(Float64,PROJECTION)) #zeros(proj_val))
    return model
end

function projection(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return proj
end

#INT($B$3+A12/12)
function age(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return trunc(Int, policy.Age + trunc(Int, proj/12))
end

#$B$4+A12
function duration(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return policy["DurationInforceMonths"] + proj
end

function mort(proj, policy, mortality, lapse, yieldc, model, prev_model)
    try
        return mortality[mortality.Age .== trunc(Int, policy.Age + trunc(Int, proj/12)), :qx][1]
    catch
        return prev_model[4]
    end
end

#IF(INT((C12-1)/12)+1>'Lapse Table'!$A$11,E11,VLOOKUP(INT((C12-1)/12)+1,'Lapse Table'!$A$2:$B$11,2,FALSE))/12
function lapserate(proj, policy, mortality, lapse, yieldc, model, prev_model)
    try
        return lapse[lapse.Duration .== trunc(Int, trunc(Int, policy["DurationInforceMonths"] + proj - 1)/12) + 1, :AnnualLapseRate][1]/12
    catch
        try
            return prev_model[5]
        catch
            return 0
        end
    end
end

#IF(A12>'Yield Curve'!A626,L11,(1+VLOOKUP(A12,'Yield Curve'!A5:B627,2,FALSE))^(1/12)-1)
function yieldcurve(proj, policy, mortality, lapse, yieldc, model, prev_model)
    try
        return ((yieldc[yieldc.Duration .== round(proj), :MonthlySpotRate][1] + 1)^(1/12))-1
    catch
        try
            return prev_model[6]
        catch
            return 0
        end
    end
end

#D12/12*(1-0.5*E12)
function deaths(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return model[4]/12 * (1-0.5*model[5])
end

#E12*(1-0.5*D12)
function surrenders(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return (1-0.5*model[4]) * (model[5])
end

#F11-G12-H12
function activepol(proj, policy, mortality, lapse, yieldc, model, prev_model)
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
function premincome(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return policy.AnnualPremium * model[9]/12
end

#$B$6*G12
function claimsoutgo(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return policy.SumAssured * model[7]
end

#I12-J12
function profit(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return model[10] - model[11]
end

#K12*(1+L12)^-A12
function presentval(proj, policy, mortality, lapse, yieldc, model, prev_model)
    return model[12] * (1 + model[6]) ^ (-1 *proj)
end

function get_value(colname, proj, policy, mortality, lapse, yieldc, model, prev_model)
    s = Symbol(colname)
    f = getfield(Main, s)
    return f(proj, policy, mortality, lapse, yieldc, model, prev_model)
end

function get_model(policies, mortality, lapse, yieldc)
    counter = 1.0
    empty_row = zeros(Float64, 13)
    policy_values = zeros(Float64, size(policies)[1])
    prev_model = empty_row
    curr_model = empty_row
    projection_range = StepRange(1, 1, PROJECTION)
    for policy in eachrow(policies)
        model = createDF(projection_range)
        col_names = names(model)
        for proj in projection_range
            prev_model = curr_model
            curr_model = empty_row
            for rno in eachindex(col_names)
                col = col_names[rno]
                val = get_value(col_names[rno], round(proj), policy, mortality, lapse, yieldc, curr_model, prev_model)
                model[model.projection .== round(proj), col_names[rno]] = val
                curr_model[rno] = val
                if col_names[rno] == "presentval"
                    policy_values[policy.PolicyIndex] += val
                end
            end
        end
        counter = counter + 1
        #println("PolicyIndex : ", policy.PolicyIndex, " policy-value : ", sum(model.presentval))
    end
    println("counter : ", counter)
    return policy_values
end

function main()
    filepath = "openASSA/POC1_Lavesh"
    filename = "Simple Life Model_Julia.xlsm"
    filename = joinpath(filepath, filename)

    mortality = DataFrame()
    lapse = DataFrame()
    yieldc = DataFrame()
    policies = DataFrame()
    all_sheets = XLSX.readxlsx(filename)
    sheet_names = XLSX.sheetnames(all_sheets)
    for sheet_name in sheet_names
        if ! (lowercase(sheet_name) in ["info", "results", "model"])
            if occursin("mortality", lowercase(sheet_name))
                mortality =  DataFrame(XLSX.readtable(filename, sheet_name)...)
            elseif occursin("lapse", lowercase(sheet_name))
                lapse =  DataFrame(XLSX.readtable(filename, sheet_name)...)
            elseif occursin("yield", lowercase(sheet_name))
                yieldc =  DataFrame(XLSX.readtable(filename, sheet_name)...)
            elseif occursin("policy", lowercase(sheet_name))
                policies =  DataFrame(XLSX.readtable(filename, sheet_name)...)
            end
        end
    end

    policy_values = @time get_model(policies, mortality, lapse, yieldc)
    println("policy_values : ", policy_values)
end

main()
println("done")
