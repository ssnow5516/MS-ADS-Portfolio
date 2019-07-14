# -*- coding: utf-8 -*-
"""
Created on Fri May 10 20:00:35 2019

@author:  Scott Snow

LAB 6
IST 718
"""

from fbprophet import Prophet
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import datetime as dt
import matplotlib.dates as mdates
import re

df1 = pd.read_csv("zillow_data.csv", encoding="latin-1")
print(df1.shape)
print(df1.columns)

df1 = df1.dropna()
print(df1.shape)
print(df1.columns)
df1.reset_index(inplace = True, drop=True)

for i,j in enumerate(df1.columns):
    print(i,j)

#---------------------------------------------------------------------------------------------------
#https://stackoverflow.com/questions/9627686/plotting-dates-on-the-x-axis-with-pythons-matplotlib
years_months = [dt.datetime.strptime(x,"%Y-%m") for x in df1.columns[16:]]


target_metros = ["Hot Springs", "Little Rock-North Little Rock-Conway", "Fayetteville-Springdale-Rogers", "Searcy"]

fig1 = plt.figure(figsize=(15,12))
fig2 = plt.figure(figsize=(15,12))

for i,j in enumerate(target_metros):

    this_df = df1.iloc[[x for x in range(df1.shape[0]) if df1.loc[x,"Metro"] == j and df1.loc[x,"State"] == "AR"],16:]
    this_vals = [np.mean(this_df[x]) for x in this_df.columns]
    this_fig = fig1.add_subplot(2,2,i+1)
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.gca().xaxis.set_major_locator(mdates.YearLocator())
    this_fig.plot(years_months,this_vals)
    plt.plot(years_months,this_vals, label=j)
    plt.gcf().autofmt_xdate()
    this_fig.set_title("%s" % re.sub("-.*","",j))
    
    
plt.suptitle("Average Housing Values of Major Metro Areas, Arkansas 1997-Present")
fig1.suptitle("Average Housing Values of Major Metro Areas, Arkansas 1997-Present")
plt.xlabel("Date")
plt.ylabel("Housing Value")
plt.legend(loc="upper left")
plt.show()
#-------------------------------------------------------------------------------

## treat (Present - 1997) values as data set
## show histogram

difference_vals = [df1.loc[x,"2019-03"]-df1.loc[x,"1997-01"] for x in range(df1.shape[0])]
plt.hist(difference_vals)
plt.title("Distribution of Housing Price Differences from 1997-Present")
plt.show()
## find difference between max month and present
## show histogram

max_diff_vals = [df1.loc[x,"2019-03"]-max(df1.iloc[x,7:]) for x in range(df1.shape[0])]
nonzero_ind = [x for x in range(len(max_diff_vals)) if max_diff_vals[x] != 0 and max_diff_vals[x] > -200000]
plt.hist([max_diff_vals[x] for x in nonzero_ind])
plt.title("Distribution of Housing Price Differences between Price Peak and Present")
plt.xlabel("Present-Price Peak")
plt.show()

## distribution of current prices
current_prices = [df1.loc[x,"2019-03"] for x in range(df1.shape[0])]
plt.hist(current_prices)


#-------------------------------------------------------------------------------------------------------
## https://facebook.github.io/prophet/docs/quick_start.html#python-api
## initial test of prophet produces clock time of 4 seconds. For all rows in zillow data, that equals 14 hours. 
import time
t1 = time.clock()
reg_df = pd.DataFrame({"ds":years_months[:252], "y":df1.iloc[0,16:268]})

m = Prophet()
m.fit(reg_df)

future = m.make_future_dataframe(periods=12, freq="M")
future.tail()

forecast = m.predict(future)
pred_2018 = forecast[["ds","yhat","yhat_lower","yhat_upper"]].tail(13)
pred_2018.reset_index(inplace = True, drop=True)
print(pred_2018.loc[12,"yhat"]/pred_2018.loc[0,"yhat"])
t2 = time.clock()
print(t2-t1)
#------------------------------------------------------------------------------
## alt approach
## forecast metro areas, then forecast individual zips in top X areas.
## X is the amount to obtain a sample size of approx 3000 zips.  

metro_list = list(set(df1["Metro"]))
metro_dict = {}

len(metro_list)
t1 = time.clock()
for metro in metro_list:
    this_df = df1.iloc[[x for x in range(df1.shape[0]) if df1.loc[x,"Metro"] == metro],16:268]
    this_vals = [np.mean(this_df[x]) for x in this_df.columns]
    this_reg_df = pd.DataFrame({"ds":years_months[:252],"y":this_vals})
    
    this_m = Prophet()
    this_m.fit(this_reg_df)
    
    future = this_m.make_future_dataframe(periods=12,freq="M")
    this_forecast = this_m.predict(future)
    this_pred_18 = this_forecast[["ds","yhat","yhat_lower","yhat_upper"]].tail(13)
    this_pred_18.reset_index(inplace = True, drop=True)
    pop_inc = this_pred_18.loc[12,"yhat"]/this_pred_18.loc[0,"yhat"] 
    metro_dict[metro] = pop_inc

t2 = time.clock()
print(t2-t1)
metro_dict.keys()

output = open("metro_house_inc_2018.txt", "w")
for x in metro_dict:
    str1 = str(x) + ": " + str(metro_dict[x]) + "\n"
    output.write(str1)
    
#-------------------------------------------------------------------------------
## based on top 80 metros which returned 557 zips, 80 selected which returned 2311. 
## approx 3.2 hours of processing time
metros_sample_size = 80
metro_tuples = []
for x in metro_dict:
    metro_tuples.append((metro_dict[x],x))
    
top_metros = sorted(metro_tuples,reverse=True)[:metros_sample_size]
top_metros = [top_metros[x][1] for x in range(metros_sample_size)]
top_zips = [df1.loc[x,"RegionName"] for x in range(df1.shape[0]) if df1.loc[x,"Metro"] in top_metros]

len(top_zips)
#-------------------------------------------------------------------------------
##

sample_ind = [x for x in range(df1.shape[0]) if df1.loc[x,"RegionName"] in top_zips]
sample_df = df1.iloc[sample_ind,:]
sample_df.shape
sample_df.reset_index(inplace = True, drop=True)

count = 0
zip_dict = {}
t1 = time.clock()
for zips in sample_df["RegionName"]:
    print(count)
    #if count > 5:
     #   break
    this_df = sample_df.iloc[[x for x in range(sample_df.shape[0]) if sample_df.loc[x,"RegionName"] == zips],16:268]
    this_vals = this_df.values.tolist()[0]
    this_reg_df = pd.DataFrame({"ds":years_months[:252],"y":this_vals})
    
    this_m = Prophet()
    this_m.fit(this_reg_df)
    
    future = this_m.make_future_dataframe(periods=12,freq="M")
    this_forecast = this_m.predict(future)
    this_pred_18 = this_forecast[["ds","yhat","yhat_lower","yhat_upper"]].tail(13)
    this_pred_18.reset_index(inplace = True, drop=True)
    pop_inc = this_pred_18.loc[12,"yhat"]/this_pred_18.loc[0,"yhat"] 
    zip_dict[zips] = pop_inc
    count += 1
t2 = time.clock()
print(t2-t1)

output = open("zipcode_house_inc_2018.txt", "w")
for x in zip_dict:
    str1 = str(x) + ": " + str(zip_dict[x]) + "\n"
    output.write(str1)
    
#--------------------------------------------------------------------------------
zips_tuples = []
for x in zip_dict:
    zips_tuples.append((zip_dict[x],x))
    
top_zips = sorted(zips_tuples, reverse=True)[:100]
print(top_zips[:3])
#-------------------------------------------------------------------------------
## timeline visuals to confirm. looking at top 4

fig3 = plt.figure(figsize=(15,12))
fig4 = plt.figure(figsize=(15,12))

for x in range(9):
    this_fig = fig3.add_subplot(3,3,x+1)
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.gca().xaxis.set_major_locator(mdates.YearLocator())
    this_df = sample_df.iloc[[k for k in range(sample_df.shape[0]) if sample_df.loc[k,"RegionName"] == top_zips[x][1]],16:268]
    this_vals = this_df.values.tolist()[0]
    this_fig.plot(years_months[:252], this_vals)## correct after code
    plt.plot(years_months[:252], this_vals, label=top_zips[x][1])
    plt.gcf().autofmt_xdate()
    this_fig.set_title(top_zips[x][1])
    
    
fig3.suptitle("Average Housing Value of Top 4 Zip Codes, 1997-2017")
plt.title("Average Housing Value of Top 4 Zip Codes, 1997-2017")
plt.xlabel("Date")
plt.ylabel("Housing Value")
plt.legend(loc="best")
plt.show()

#-------------------------------------------------------------------------------
## compare to adjusted gross income
## import data.all or lookup state file
## check number of returns in classes:

#1 = $1 under $25,000
#2 = $25,000 under $50,000
#3 = $50,000 under $75,000
#4 = $75,000 under $100,000
#5 = $100,000 under $200,000
#6 = $200,000 or more

## divide Joint by 2 and head of household by three
## compare sorted values in Agi groups to top_zips
## find highest union values. 
## Check vis. stacked bar graph for top 10 zips pop growth value
# bars sorted by population growth

df_income = pd.read_csv("lab2/16zpallagi.csv")
income_dict = {}
for x in top_zips[:10]:
    income_dict[x[1]] = []
    for k in np.arange(1,7,1):
        income_dict[x[1]].append(df_income.loc[
                [s for s in range(df_income.shape[0]) if df_income.loc[s,"zipcode"] == x[1] and df_income.loc[s,"agi_stub"] == k]
                ,"N1"].tolist()[0])
    
df_zip_inc = pd.DataFrame(income_dict)
agi_bins = {1:"1-25,000", 2:"25,000-50,000", 3:"50,000-75,000", 4:"75,000-100,000"
            ,5:"100,000-200,000",6:"200,000+"}

##https://matplotlib.org/gallery/lines_bars_and_markers/bar_stacked.html
ind = np.arange(9)
lofbars = []
plt.figure(figsize=(15,12))  
for x in range(df_zip_inc.shape[0]):
    lofbars.append(plt.bar(ind, df_zip_inc.iloc[x,0:9], label=agi_bins[x+1], width=.95))

  
plt.ylabel("Tax Filers")
plt.title("Income by Bracket of Top 9 Projected Growth Zips")
plt.xticks(ind, df_zip_inc.columns[0:9])
plt.xlabel("Zip Code")
plt.legend(lofbars,[agi_bins[x] for x in np.arange(1,7,1)])
plt.show()


