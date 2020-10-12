"""This is POC code for OpenASSA. Its dependencies are pandas, xlrd and flask.
Run using - python assa_poc.py runserver"""
from multiprocessing import Pool, cpu_count
import sys
import time
#import pdb; pdb.set_trace()

from flask import Flask, render_template
import pandas as pd

FLASK_APP = Flask(__name__)
PROJECTION = '2140M'# '2140M'
PARALLELIZATION = 1
"""TODO: We need to create a class for policy and also add get and set methods for each column
including calculated columns. Also, we need to add exception handling."""

def _eval_policy_rules(index, idx, policy, columns_list, init_rules, init_rules_keyerror,\
        rules, rules_keyerror, projection, mortality, lapse, yieldc, parallelize=False):
    try:
        dfs = pd.DataFrame(columns=columns_list)
        df = prev_df = []
        proj = 1
        for key, rule in init_rules.items():
            try:
                df.append(eval(rule, {"index" : index, "idx" : idx, "projection" : proj,\
                    "policy" : policy, "mortality" : mortality, "lapse" : lapse, "yieldc" : yieldc,\
                    "df" : df, "prev_df" : prev_df}))
            except KeyError:
                df.append(eval(init_rules_keyerror[key], {"index" : index, "idx" : idx,\
                    "projection" : proj, "policy" : policy, "mortality" : mortality,\
                    "lapse" : lapse, "yieldc" : yieldc, "df" : df, "prev_df" : prev_df}))
        dfs.loc[len(dfs)] = df
        prev_df = df
        index += 1
        for proj in range(2, projection+1):
            df = []
            for key, rule in rules.items():
                try:
                    df.append(eval(rule, {"index" : index, "idx" : idx, "projection" : proj,\
                        "policy" : policy, "mortality" : mortality, "lapse" : lapse,\
                        "yieldc" : yieldc, "df" : df, "prev_df" : prev_df}))
                except KeyError:
                    df.append(eval(rules_keyerror[key], {"index" : index, "idx" : idx,\
                        "projection" : proj, "policy" : policy, "mortality" : mortality,\
                        "lapse" : lapse, "yieldc" : yieldc, "df" : df, "prev_df" : prev_df}))

            dfs.loc[len(dfs)] = df
            index += 1
            prev_df = df
        if parallelize:
            return (idx, round(dfs['presentval'].sum() * -1, 2))
        else:
            return (idx, round(dfs['presentval'].sum() * -1, 2))
    except:
        raise

def _get_liability(columns_list, init_rules, init_rules_keyerror, rules,\
    rules_keyerror, policies, mortality, lapse, yieldc):
    try:
        if 'M' in PROJECTION:
            projection = int(PROJECTION.split('M')[0])
        elif 'Y' in PROJECTION:
            projection = int(PROJECTION.split('Y')[0]) * 12
        pol_liab = []
        index = 0
        for idx, policy in policies.iterrows():
            dfs = _eval_policy_rules(index, idx, policy, columns_list, init_rules,\
                init_rules_keyerror, rules, rules_keyerror, projection, mortality,\
                lapse, yieldc)
            pol_liab.append(dfs)

        return pol_liab
    except:
        raise

def _get_liability_parallel(columns_list, init_rules, init_rules_keyerror, rules,\
    rules_keyerror, policies, mortality, lapse, yieldc):
    try:
        if 'M' in PROJECTION:
            projection = int(PROJECTION.split('M')[0])
        elif 'Y' in PROJECTION:
            projection = int(PROJECTION.split('Y')[0]) * 12

        index = 0
        print("parallelization factor : ", cpu_count() * PARALLELIZATION)
        pool = Pool(cpu_count() * PARALLELIZATION)
        pol_liab = [pool.apply_async(_eval_policy_rules, (index, idx, policy, \
            columns_list, init_rules, init_rules_keyerror, rules, rules_keyerror, projection,\
            mortality, lapse, yieldc, True)) for idx, policy in policies.iterrows()]

        return pol_liab
    except:
        raise

def _dict_to_pd(data, cols):
    df = pd.DataFrame(columns=cols)
    for key, value in data.items():
        df.loc[len(df)] = [key, value]
    return df

def _pd_to_html(df):
    return df.to_html(classes='table table-striped table-hover table-sm table-responsive-sm')\
        .replace('dataframe ', '').replace(' border="1"', '')

@FLASK_APP.route("/")
def show_tables():
    """Main driver function used to calculate all policy liabilities.
    It is used for landing page route."""
    try:
        columns_list = ['idx', 'policyid', 'projection', 'age', 'duration', 'mortality',\
            'lapse', 'yieldc', 'deaths', 'surrenders', 'activepol', 'premincome', 'claimsoutgo',\
            'profit', 'presentval']
        pol_val_cols = ['policyid', 'liability']
        rules_columns = ['rule-name', 'rule']

        init_rules = {
            "idx" : "index", \
            "policyid" : "idx",\
            "projection" : "projection",\
            "age" : "policy['Age'] + int(projection/12)",\
            "duration" : "int(policy['Duration Inforce (Months)']) + projection",\
            "mortality" : "mortality.loc[policy['Age'] + int(projection/12)]['qx']",\
            "lapse" : "lapse.loc[int((int(policy['Duration Inforce (Months)']) +\
                projection - 1)/12)+1]['Annual Lapse Rate']/12",\
            "yieldc" : "float(yieldc.loc[projection]['Spot Rate (NACA)']+1) ** (1/12)-1",\
            "deaths" : "(df[5]/12) * (1 - (0.5 * df[6]) )",\
            "surrenders" : "df[6] * (1 - (0.5 * df[5]) )",\
            "activepol" : "1-df[8]-df[9]",\
            "premincome" : "df[10] * (policy['Annual Premium']/12)",\
            "claimsoutgo" : "df[8] * policy['Sum Assured']",\
            "profit" : "df[11]-df[12]",\
            "presentval" : "df[13]* ((1+df[7]) ** -(projection))"
            }

        init_rules_keyerror = {
            "lapse" : "0"
            }

        #rules changed between init_rules and rules: activepol
        rules = {
            "idx" : "index", \
            "policyid" : "idx",\
            "projection" : "projection",\
            "age" : "policy['Age'] + int(projection/12)",\
            "duration" : "int(policy['Duration Inforce (Months)']) + projection",\
            "mortality" : "mortality.loc[policy['Age'] + int(projection/12)]['qx']",\
            "lapse" : "lapse.loc[int((int(policy['Duration Inforce (Months)']) +\
                projection - 1)/12)+1]['Annual Lapse Rate']/12",\
            "yieldc" : "float(yieldc.loc[projection]['Spot Rate (NACA)']+1) ** (1/12)-1",\
            "deaths" : "(df[5]/12) * (1 - (0.5 * df[6]) )",\
            "surrenders" : "df[6] * (1 - (0.5 * df[5]) )",\
            "activepol" : "prev_df[10]-df[8]-df[9]",\
            "premincome" : "df[10] * (policy['Annual Premium']/12)",\
            "claimsoutgo" : "df[8] * policy['Sum Assured']",\
            "profit" : "df[11]-df[12]",\
            "presentval" : "df[13]* ((1+df[7]) ** -(projection))"
            }

        rules_keyerror = {
            "mortality" : "prev_df[5]",\
            "lapse" : "prev_df[6]",\
            "yieldc" : "prev_df[7]",\
            "activepol" : "1-df[8]-df[9]"
            }

        st = time.time()
        rules_dict = _dict_to_pd(rules, rules_columns)
        rules_keyerror_dict = _dict_to_pd(rules_keyerror, rules_columns)
        rules_init_dict = _dict_to_pd(init_rules, rules_columns)
        rules_init_keyerror_dict = _dict_to_pd(init_rules_keyerror, rules_columns)

        all_sheets = pd.ExcelFile('Simple Life Model.xlsm')

        ds = {sheet_name: all_sheets.parse(sheet_name).dropna()\
            .set_index(all_sheets.parse(sheet_name).dropna().columns[0])\
                for sheet_name in all_sheets.sheet_names \
                if sheet_name.lower() not in ['results', 'model']}
        for key in ds.keys():
            if 'mortality' in key.lower():
                mortality = ds[key]
            elif 'lapse' in key.lower():
                lapse = ds[key]
            elif 'yield' in key.lower():
                yieldc = ds[key]
            elif 'policy' in key.lower():
                policies = ds[key]
        st_s = time.time()
        """
        result = _get_liability(columns_list, init_rules, \
            init_rules_keyerror, rules, rules_keyerror, policies, mortality, lapse, yieldc)
        #st_p = time.time()
        #print("time taken : ", st_p-st_s)
        """
        result = _get_liability_parallel(columns_list, init_rules, \
            init_rules_keyerror, rules, rules_keyerror, policies, mortality, lapse, yieldc)
        result = [res.get(timeout=60) for res in result]
        #"""
        et_p = time.time()
        result = pd.DataFrame(result, columns=pol_val_cols)
        result = result.set_index('policyid')
        print(result)
        print("time taken (parallel): ", et_p-st_s)
        #result.to_csv("model.csv")
        tables = {'policies' : _pd_to_html(policies), 'mortality': _pd_to_html(mortality),\
                'lapse' : _pd_to_html(lapse), 'yieldc' : _pd_to_html(yieldc),\
                'rules' : _pd_to_html(rules_dict),\
                'rules_keyerror' : _pd_to_html(rules_keyerror_dict),\
                'rules_init' : _pd_to_html(rules_init_dict),\
                'rules_init_keyerror' : _pd_to_html(rules_init_keyerror_dict),\
                'result' : _pd_to_html(result)}
        et = time.time()
        print("total time taken : ", et-st)
        return render_template('main.html', tables=tables)
    except KeyboardInterrupt:
        sys.exit(0)

if __name__ == "__main__":
    FLASK_APP.run(debug=True)
