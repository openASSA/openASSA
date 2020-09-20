
###############################################Init########################################################################
import findspark

findspark.init()

import time

import pyspark

from pyspark.sql import SparkSession
from pyspark.sql import Row
import pyspark.sql.functions as F
from pyspark.sql.types import *


#Creates the spark environment and sets up basis config
spark = SparkSession.builder.master("local[*]").config("spark.executor.memory", "4g")\
.config("spark.driver.memory", "4g").config("spark.memory.offHeap.enabled", True)\
.config("spark.memory.offHeap.size","4g").config("Spark.sql.warehouse.dir").appName("POC")\
.getOrCreate()

#Directory to write temp dataframes when the maximum memory is exceeded
spark.sparkContext.setCheckpointDir("/tmp")

###############################################Functions########################################################################

#Simple function which calls the Spark data important function, this function can expanded to connect to databases,
# as well as allowing for the scheme to be manually inputted.
def import_data(table_input,file_type,delimit):
    table = spark.read.load(table_input, format = file_type , sep=delimit, inferSchema="true", header="true")
    return (table)

# This function appends the decrement/yield data to the policy data for at a specific point in time, and increments the time
# dependent variables. It takes as an input the policy dataframe, the decrement dataframe (e.g. mortality, lapse, yield curve),
# the index value in both dataframes to look up and the amount by which to increment the policy index variable.
# There is some work to make this function a bit more effcient.

def tables_append(policies, table, policy_index,table_index,table_ref,incr,index_name):
    newpolicies = policies.drop(table_ref)
    max_value = table.agg(F.max(table[table_index])).head()[0]
    newpolicies = newpolicies.select(F.col("*"), F.when((newpolicies[policy_index]+F.lit(incr)) > max_value, max_value).otherwise(newpolicies[policy_index]+F.lit(incr)).alias("temp"))
    newpolicies = newpolicies.drop(index_name)
    newpolicies = newpolicies.withColumnRenamed("temp",index_name)
    newpolicies = newpolicies.drop("temp")
    value = newpolicies.join(table, [F.greatest(F.floor(newpolicies[index_name]),F.lit(1)) == table[table_index]], how='left').select(newpolicies["*"], table[table_ref])
    return(value)

###############################################Main Program########################################################################

# Import all the data and convert to spark dataframes, please specify location
mort_table = import_data("C:///Users\saa2005\github\openASSA\POC1_Sean\Mortality_Table.txt","csv","\t")
lapse_table = import_data("C:///Users\saa2005\github\openASSA\POC1_Sean\Lapse_Table.txt","csv","\t")
yield_curve = import_data("C:///Users\saa2005\github\openASSA\POC1_Sean\Yield_Curve.txt","csv","\t")
policy_data = import_data("C:///Users\saa2005\github\openASSA\POC1_Sean\Policy_Data.txt","csv","\t")

#The first append to get all the necassary values for the calc at time 1
mort = tables_append(policy_data,mort_table,"Age","Age","qx",1/12,"Current_Age")
lapses_policy_data = mort.withColumn("Duration_Inforce_Years", policy_data["Duration_Inforce_Months"]/12+F.lit(1))
Lapses = tables_append(lapses_policy_data,lapse_table,"Duration_Inforce_Years","Duration_Years","Annual_Lapse_Rate",1/12,"Current_Duration")
Final = tables_append(Lapses, yield_curve, "Duration_Inforce_Months","Duration_Months","Spot_Rate_NACA",1,"Current_Yield")
Final = Final.withColumn("NO_DEATHS", F.lit(1))
Final = Final.withColumn("NO_LAPSES", F.lit(1))
Final = Final.withColumn("NO_POLS_IF", F.lit(1))
Final = Final.withColumn("PV", F.lit(0))

# Key columns needed from the policy data needed in the final output
# This idea of specifying the SQL query can be made generic so you can input the calcs as well
core_Columns = "Policy_Index, Age, Annual_Premium, Sum_Assured, Duration_Inforce_Months, Current_Age, qx, Duration_Inforce_Years, Current_Duration, Annual_Lapse_rate, Current_Yield, Spot_rate_NACA"

# Main calculations and loop through time
# The SQL query must be read from the bottom up to make sense. The first step is to calculate the decrements
# the second to to calculate the inforce index_policies,
# the third to calculate the profit
# the last step is to discount the profit abd add to teh previous result.
for i in range(0, 1200):
    Final.registerTempTable("view1")
    Final2 = spark.sql("""
    SELECT {core_Columns}, PREM_INC, CLAIMS_OUTGO,  PROFIT, NO_POLS_IF, NO_DEATHS, NO_LAPSES, PV + PROFIT*pow(1+Spot_Rate_NACA, ({i}/12)) as PV FROM
    (
    SELECT *, PREM_INC - CLAIMS_OUTGO as PROFIT FROM
    (
    SELECT *, Annual_Premium/12*NO_POLS_IF as PREM_INC, Sum_Assured*NO_DEATHS as CLAIMS_OUTGO FROM
    (
    SELECT {core_Columns}, PV, NO_DEATHS, NO_LAPSES, NO_POLS_IF-NO_DEATHS-NO_LAPSES as NO_POLS_IF FROM
    (
    SELECT {core_Columns}, PV, NO_POLS_IF, NO_POLS_IF * qx /12 *(1-0.5*Annual_Lapse_Rate/12) as NO_DEATHS, NO_POLS_IF * Annual_Lapse_Rate/12*(1-0.5*qx/12) as NO_LAPSES FROM view1
    )
    )
    )
    )""".format(core_Columns=core_Columns,i=str(-1*(i+1))))
    Final = None
    Final3 = tables_append(Final2, mort_table,"Current_Age","Age","qx",1/12,"Current_Age")
    Final4 = tables_append(Final3,lapse_table,"Current_Duration","Duration_Years","Annual_Lapse_Rate",1/12,"Current_Duration")
    Final5 = tables_append(Final4, yield_curve, "Current_Yield","Duration_Months","Spot_Rate_NACA",1,"Current_Yield")
    # This section manages the memory and trims the dataframe tree every 20 iteration.
    # It needs to be made more dynamic and rather execute when memory is low
    if i%20 == 0 :
        Final = Final5.checkpoint()
    else :
        Final = Final5
    Final2 = None
    Final3 = None
    Final4 = None
Final.show()
# This can be made more generic to specify the type of output as well as the file name.
Final.coalesce(1).write.mode("overwrite").option("header","true").csv("C:///Users\saa2005\github\openASSA\POC1_Sean_Results")
