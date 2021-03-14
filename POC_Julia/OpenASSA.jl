
#This program contains the basic building blocks for a life valuation model in Julia. It is broken down into three basic sections.
#1. A set of formula/functions which defines the product rules and reserving calculations.
#2. A calculation engine which executes these formulas/functions over time, and outputs the results
#3. An input and output function which reads and writes data in the form of json files.

#This is intended as a first stab at a solution and therefore there remains a lot fo work to build the relevant functions out. This is high-lighted in the various 
# sections of code.

#import Pkg;
#Pkg.add("JSON")        This code is used to import the relevant packages. The progam uses the Julia JSON package and the Threads functions in the standard library.
#Pkg.update()           The use of external packages has been kept to the minimun.

using .Threads
using JSON
export JSON, JSONText, json

##############################################################################################################################################################
# This is the calculation engine which executes the functions. It essential consists of two loops, one to loop through the policies and the other to loop through
# the projection period. The calculations engine currently uses multi-threading on the outer loop (policies) to speed up the processing. This can easily be converted
# to distributed computing using the standard distribution Julia library. Future work would involve creating a version of this for distributed computing. All the outputs
# written to a dictionary. Dictionaries are a bit slower than arrays but is make eaiser to query.
###############################################################################################################################################################

function CalcEngine(Policy, Mortality, Lapse, Yield, proj_term, proj_out,get_policy_details, f)
    FinalResult = Dict(Policy[i]["Policy_Index"]=>Dict() for i=1:length(Policy))
    @threads for i = 1:length(Policy)
        Temp_result = []
        PolDetail = GetPolicyDetails(Policy,i)
        Result = []
        for t = 1:proj_term
            Result = f.StartCalc(PolDetail, Mortality, Lapse, Yield,t,Result,f)
        end
        FinalResult[PolDetail.Pol_index] = Result
    end
    return FinalResult
end

###############################################################################################################################################################
#The following functions are the product rules/reserving calculations for a simple term assurance contract. The FstartCalc function is used to initialise init_variables
#as well as determine the order of execution of the product rules/reverving calculations. Currently it requires the user to code the correct order and parameters to 
#pass, however future work can involve changing this to a function which can pick up order and parameters from the functions themselves. The functions themselves currently
# are structured as a set on indepedent functions, which works ok if there is only one simple product. However this needs to be enhanced to put it into some sort of class
#structure which will allow multiple version of the same functions depending on the class. In addition these functions need to be moved to a separate library which can be
#pre-edited from a GUI by the user.
################################################################################################################################################################


function FstartCalc(PolDetail, Mortality, Lapse, Yield,t,Result,f)
    if t == 1
        Result = Dict("NoPolsIf"=>[1.00], "NoDeaths"=>[0.00], "NoLapses"=>[0.00],"PremInforce"=>[PolDetail.AP], "DeathOutgo"=>[0.00], 
            "PVPremArray"=>[PolDetail.AP], "PVDeathArray"=>[0.00],"PVProfit"=>[0.00],"Reserve"=>[0.00])
    end
    Current_Age = f.IndexAge(PolDetail.Age,t)
    Current_DurM = f.IndexDurM(PolDetail.DM,t)
    Current_DurY = f.IndexDurY(Current_DurM)
    InterestRate = f.InterestRate(Yield,div(t,12)+1)
    NoPolsIfArray = f.NoPolsIf(Lapse,Current_DurY,Mortality,Current_Age,t,Result["NoPolsIf"],Result["NoDeaths"],Result["NoLapses"],f)
    PremiumInfArray = f.PremiumInforce(PolDetail.AP,Result["NoPolsIf"][t+1],Result["PremInforce"])
    DeathOutgoArray = f.DeathOutgo(PolDetail.SA,Result["NoDeaths"][t+1],Result["DeathOutgo"])
    PVPremiumArray = f.PV(Result["PremInforce"][t+1],InterestRate,Result["PVPremArray"],t,"PVPremArray")
    PVDeathArray = f.PV(Result["DeathOutgo"][t+1],InterestRate,Result["PVDeathArray"],t,"PVDeathArray")
    PVProfitArray = f.PVProfit(Result["PVPremArray"][t+1],Result["PVDeathArray"][t+1],Result["PVProfit"])
    ReserveArray = f.Reserve(Result["PVProfit"][t+1],Result["Reserve"])
    Result = merge(Dict("PolicyIndex"=>PolDetail.Pol_index),NoPolsIfArray,PremiumInfArray,DeathOutgoArray,PVPremiumArray,PVDeathArray,PVProfitArray,ReserveArray)
    return Result
end

FindexAge(Age,t) = Age + div(t,12)
FindexDurM(Duration,t) = Duration + t
FindexDurY(Duration) = div(Duration,12)+1

function FlapseRate(Lapse_Table,Current_DurY)
    max_table = maximum(keys(Lapse_Table[2]))
    if string(Current_DurY) > max_table
        return get(Lapse_Table[2],max_table,0)
    else
        return get(Lapse_Table[2],string(Current_DurY),0)
    end
end

function Fqx(Mortality_Table,Current_Age)
    max_table = maximum(keys(Mortality_Table[2]))
    if "Age"*string(Current_Age) > max_table
        return get(Mortality_Table[2],max_table,0)
    else
        return get(Mortality_Table[2],"Age"*string(Current_Age),0)
    end
end

function FInterestRate(YieldTable,t)
    max_table = maximum(keys(YieldTable[2]))
    if string(t) > max_table
        return get(YieldTable[2],max_table,0)
    else
        return get(YieldTable[2],string(t),0)
    end
end

function FnoLapses(lapse_rate,No_pols_if_value)
     return No_pols_if_value*lapse_rate/12
end

function FnoDeaths(qx,No_pols_if_value)
    return No_pols_if_value*qx/12
end

function FnoPolsIf(Lapse_Table,Current_DurY,Mortality_Table,Current_Age,t,NoPolsIfArray,NoDeathsArray,NoLapsesArray,f)
    lapse_rate = f.LapseRate(Lapse_Table,Current_DurY)
    qx = Fqx(Mortality_Table,Current_Age)
    NoLapses = f.NoLapses(lapse_rate,NoPolsIfArray[t])
    NoDeaths = f.NoDeaths(qx,NoPolsIfArray[t])
    Current_pols_if = NoPolsIfArray[t] - NoLapses - NoDeaths
    OutputPolsIf = push!(NoPolsIfArray,Current_pols_if)
    OutputNoDeaths = push!(NoDeathsArray,NoDeaths)
    OutputNoLapses = push!(NoLapsesArray,NoLapses)
    return Dict("NoPolsIf"=> OutputPolsIf, "NoDeaths"=>OutputNoDeaths, "NoLapses"=>OutputNoLapses)
end

function FPremiumInforce(AP,NoPolsIf,PremiumInfArray)
    result = AP*NoPolsIf
    resultArray = push!(PremiumInfArray,result)
    return Dict("PremInforce"=> resultArray)
end

function FDeathOutgo(SA,NoDeaths,DeathOutgoArray)
    result = SA*NoDeaths
    resultArray = push!(DeathOutgoArray,result)
    return Dict("DeathOutgo"=>resultArray)
end

function FPV(Amount,InterestRate,PVArray,t,name)
    result = Amount*(1+InterestRate)^(-t/12)
    resultArray = push!(PVArray,result)
    return Dict(name=>resultArray)
end

function FPVProfit(Premium,Claim,PVProfit)
    result = Premium - Claim
    resultArray = push!(PVProfit, result)
    return Dict("PVProfit"=> resultArray)
end

function FReserve(PVProfit,Reserve)
    push!(Reserve, 0)
    result = Reserve .- PVProfit
    return Dict("Reserve" => result)
end

############################################################################################################################################################################
# The next set of functions are some simple data handling functions. The first function fetches the policy data need for the calculation. Again this a manual but can be made
# to be more automatic, given the functions. The second is a simple write function which outputs the results to a JSON file. It currently outputs an array of the policy details
# as well as the reserve. It can be modified to output more. Ideally it should take as an input a list of variables which need to be outputted as well as the time period. 
############################################################################################################################################################################


function GetPolicyDetails(Policy,i)
    Policy_Index = get(Policy[i],"Policy_Index",3)
    Annual_Premium = get(Policy[i],"Annual_Premium",3)
    Ages = get(Policy[i],"Age",3)
    Sum_Assured = get(Policy[i],"Sum_Assured",3)
    Duration_Inforce_Months = get(Policy[i],"Duration_Inforce_Months",3)
    return (Pol_index=Policy_Index, AP=Annual_Premium , Age=Ages, SA=Sum_Assured, DM=Duration_Inforce_Months)
end

function output(results, size,PolicyData)
    reserve_results = []
    for i = 1:size
        Pol_Details = PolicyData[i]
        Pol_indx = Pol_Details["Policy_Index"]
        Output = merge(Pol_Details,Dict("Reserve"=>results[Pol_indx]["Reserve"][1]))
        reserve_results = push!(reserve_results,Output)
    end
    JSON_Final_results = JSON.json(reserve_results)
    open("Final_Results.json","w") do f
        JSON.write(f,JSON_Final_results)
    end
    return
end

#The array f is used to pass all the functions needed to the CalcEngine. It would be useful if this could be auto generated from the functions above.

f = (StartCalc = FstartCalc, IndexAge = FindexAge, IndexDurM = FindexDurM, IndexDurY = FindexDurY, NoPolsIf = FnoPolsIf, NoDeaths = FnoDeaths, 
    NoLapses=FnoLapses, LapseRate = FlapseRate, qx = Fqx, PremiumInforce = FPremiumInforce, DeathOutgo = FDeathOutgo, PV = FPV, InterestRate = FInterestRate, 
        PVProfit = FPVProfit, Reserve = FReserve)

##########################################################################################################################################################################
#The code below simply loads the policy and other data from json files. It assumes the files are in specific formats. Ultimately code needs to be developed which can convert
#specific formats into the json files. The user will have to enter the formula as well as a mapping of the data to the required fields in the code. This will ensure that the
#code is easy to use with multiple data sources.
########################################################################################################################################################################## 

PolicyData = JSON.parsefile("C:/Users/saa2005/github/openASSA/POC_Julia/Policy_Data.json")
LapseTable = JSON.parsefile("C:/Users/saa2005/github/openASSA/POC_Julia/Lapse_Table2.json")
MortalityTable = JSON.parsefile("C:/Users/saa2005/github/openASSA/POC_Julia/Mortality_Table2.json")
YieldCurve = JSON.parsefile("C:/Users/saa2005/github/openASSA/POC_Julia/Yield_Curve2.json")

##########################################################################################################################################################################
#The following code is the main code which executes the program. For testing it includes a print function which prints the number of threads and @time is used to time
#the calculations. If the @thread macro is removed from the CalcEngine code the time benefit of multi-threading can be obtained.
##########################################################################################################################################################################

print(Threads.nthreads())
@time results = CalcEngine(PolicyData,MortalityTable,LapseTable,YieldCurve,1440,10,GetPolicyDetails,f)
print("Calc Results")
test = output(results,length(PolicyData),PolicyData)

