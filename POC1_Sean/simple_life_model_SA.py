#!/usr/bin/env python
# coding: utf-8

# In[1]:


import findspark

findspark.init()                #Finds the local install of spark on the machine

import pyspark

from pyspark.sql import SparkSession
from pyspark.sql import Row
import pyspark.sql.functions as F
from pyspark.sql.types import *

spark = SparkSession.builder.master("local[*]").config("spark.executor", "4g").config("spark.driver.memory","4g").config("spark.memory.offHeap.enabled", True)\
.config("spark.memory.offHeap.size","4g").config("Spark.sql.warehouse.dir").appName("POC").getOrCreate()
spark.sparkContext.setCheckpointDir("/tmp")

def import_data(table_input,file_type,delimit):
    table = spark.read.load(table_input, format = file_type , sep=delimit, inferSchema="true", header="true")
    return (table)

def projected_mort_rates(policies, table, policy_index,table_index,table_ref,incr,index_name):
    #policies.createOrReplaceTempView("pol")
    #index_policies = spark.sql("SELECT *, "+policy_index+"+"+str(incr)+" as temp FROM pol")
    #policies = policies.withColumn(index_name,policies[policy_index])
    #policies = policies.withColumn(index_name, policies[index_name]+F.lit(incr))
    newpolicies = policies.drop(table_ref)
    max_value = table.agg(F.max(table[table_index])).head()[0]
    newpolicies = newpolicies.select(F.col("*"), F.when((newpolicies[policy_index]+F.lit(incr)) > max_value, max_value).otherwise(newpolicies[policy_index]+F.lit(incr)).alias("temp"))
    newpolicies = newpolicies.drop(index_name)
    newpolicies = newpolicies.withColumnRenamed("temp",index_name)
    newpolicies = newpolicies.drop("temp")
    #newpolicies = spark.sql("SELECT *, CASE WHEN "+index_name+" > "+str(max_value)+" THEN "+str(max_value)+" ELSE "+policy_index+" FROM pol")
    #newpolicies = newpolicies.withColumn(policy_index, F.when((newpolicies[policy_index] > max_value), max_value).otherwise(newpolicies[policy_index]))
    value = newpolicies.join(table, [F.greatest(F.floor(newpolicies[index_name]),F.lit(1)) == table[table_index]], how='left').select(newpolicies["*"], table[table_ref])
    return(value)

mort_table = import_data("C:///Users\saa2005\github\openASSA\spark-warehouse\POC1_Sean\Mortality_Table.txt","csv","\t")
lapse_table = import_data("C:///Users\saa2005\github\openASSA\spark-warehouse\POC1_Sean\Lapse_Table.txt","csv","\t")
yield_curve = import_data("C:///Users\saa2005\github\openASSA\spark-warehouse\POC1_Sean\Yield_Curve.txt","csv","\t")
policy_data = import_data("C:///Users\saa2005\github\openASSA\spark-warehouse\POC1_Sean\policy_data.txt","csv","\t")

mort = projected_mort_rates(policy_data,mort_table,"Age","Age","qx",1/12,"Current_Age")
lapses_policy_data = mort.withColumn("Duration_Inforce_Years", policy_data["Duration_Inforce_Months"]/12)
Lapses = projected_mort_rates(lapses_policy_data,lapse_table,"Duration_Inforce_Years","Duration_Years","Annual_Lapse_Rate",1/12,"Current_Duration")
Final = projected_mort_rates(Lapses, yield_curve, "Duration_Inforce_Months","Duration_Months","Spot_Rate_NACA",1,"Current_Yield")
Final = Final.withColumn("NO_DEATHS", F.lit(1))
Final = Final.withColumn("NO_LAPSES", F.lit(1))
Final = Final.withColumn("NO_POLS_IF", F.lit(1))
Final = Final.withColumn("PV", F.lit(0))
core_Columns = "Policy_Index, Age, Annual_Premium, Sum_Assured, Duration_Inforce_Months, Current_Age, qx, Duration_Inforce_Years, Current_Duration, Annual_Lapse_rate, Current_Yield, Spot_rate_NACA"
#core_Columns = "Annual_Premium, Sum_Assured, qx, Annual_Lapse_rate, Spot_rate_NACA"
for i in range(1, 1200):
    Final.registerTempTable("view")
    Final1 = spark.sql("SELECT "+core_Columns+", PV, NO_POLS_IF, NO_POLS_IF * qx /12 as NO_DEATHS, NO_POLS_IF * Annual_Lapse_Rate/12 as NO_LAPSES FROM view")
    Final1.registerTempTable("view")
    Final2 = spark.sql("SELECT "+core_Columns+", PV, NO_DEATHS, NO_LAPSES, NO_POLS_IF-NO_DEATHS-NO_LAPSES as NO_POLS_IF FROM view")
    Final2.registerTempTable("view")
    Final3 = spark.sql("SELECT *, Annual_Premium/12*NO_POLS_IF as PREM_INC, Sum_Assured*NO_DEATHS as CLAIMS_OUTGO FROM view")
    Final3.registerTempTable("view")
    Final4 = spark.sql("SELECT *, PREM_INC - CLAIMS_OUTGO as PROFIT FROM view")
    Final4.registerTempTable("view")
    Final5 = spark.sql("SELECT "+core_Columns+", PROFIT, NO_POLS_IF, NO_DEATHS, NO_LAPSES, PV + PROFIT*pow(1+Spot_Rate_NACA, "+str(-i/12)+") as PV FROM view")
    Final6 = projected_mort_rates(Final5, mort_table,"Current_Age","Age","qx",1/12,"Current_Age")
    Final7 = projected_mort_rates(Final6,lapse_table,"Current_Duration","Duration_Years","Annual_Lapse_Rate",1/12,"Current_Duration")
    Final8 = projected_mort_rates(Final7, yield_curve, "Current_Yield","Duration_Months","Spot_Rate_NACA",1,"Current_Yield")
    #if i%20 == 0 :
    #    print(str(i))
    Final = Final8.checkpoint()
    #else :
    #    Final = Final8
Final5.show()
