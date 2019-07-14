# -*- coding: utf-8 -*-
"""
Created on Sat Apr 20 09:28:49 2019

@author:  Scott Snow
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import re




## import coaches
df_coaches = pd.read_csv("coaches.tsv", delimiter="\t")
df_coaches.columns
df_coaches.shape
## get a list of conferences
df1_conf = set(df_coaches["Conference"])
#views the list of schools
#df_coaches["School"]
#------------------------------------------------------------------------------
## import graduation statistics
df_gradrates = pd.read_csv("gradrates.csv")
df_gradrates.columns
## looking at 2006 cohort for a time specific view
o6cols = [x for x in df_gradrates.columns if "2006" in x and "FEMALE" not in x]
## remove datatab columns
df_gr2 = df_gradrates[[x for x in df_gradrates.columns if "DATATAB" not in x]]
df_gr2.columns

## 2006 columns only
## df1 FBS football only
## choose the general columns to include
gencols = ["SCL_NAME","SCL_SUBDIVISION","SCL_CONFERENCE","DIV1_FB_CONFERENCE","SCL_HBCU","FED_N_SA","FED_RATE_SA","GSR_N_SA","GSR_SA","FED_RATE_MALE_AA_SA","FED_RATE_MALE_OTHER_SA","FED_RATE_MALE_WH_SA","GSR_MALE_AA_SA","GSR_MALE_OTHER_SA","GSR_MALE_WH_SA"]	
df_gr3 = df_gr2[gencols + o6cols]
df_gr3.columns

## get unique set of conferences from the graduation data
div1fb_conf = set(df_gr3.loc[[x for x in range(df_gr3.shape[0]) if df_gr3.loc[x,"SCL_SUBDIVISION"]==1], "DIV1_FB_CONFERENCE"])
## loop combines the conference list for each into a map. 
conf_map = {}
for i in range(len(df1_conf)):
    conf_map[sorted(list(df1_conf))[i]] = sorted(list(div1fb_conf))[i]

## later error, Coastal Carolina for some reason is flagged incorrectly in the data set
toadd = df_gr3[df_gr3["SCL_NAME"] =="Coastal Carolina University"]

# creates a final dataframe of only schools that play in the FBS for football
df_gr4 = df_gr3.iloc[[x for x in range(df_gr3.shape[0]) if df_gr3.loc[x,"SCL_SUBDIVISION"] ==1],:]
df_gr4.columns
df_gr4.shape
# resets the index
df_gr4.reset_index(inplace = True, drop=True)
# adds coastal carolina
df_gr4 = df_gr4.append(toadd)

#manually edit output to obtain sch_ls
#for x in range(df_gr4.shape[0]):
#    print(df_gr4.loc[x,"SCL_NAME"] + "\t" + df_coaches.loc[x,"School"])


#------------------------------------------------------------------------------
#get stadium sizes
from bs4 import BeautifulSoup
import urllib.request as req
stadium_size_url = "https://en.wikipedia.org/wiki/List_of_NCAA_Division_I_FBS_football_stadiums"
openu = req.urlopen(stadium_size_url)
html = openu.read().decode("utf8")
stsoup = BeautifulSoup(html, "html.parser")
table1 = stsoup.find_all("table",{"class":'wikitable sortable'})
## there are two wikitable sortables on this article, the second is for future planned stadiums or expansions
trls = table1[0].find_all("tr")
stmap = {'Image':[], 'Stadium':[],'City':[],'State':[],'Team':[],'Conference':[],'Capacity':[],'Record':[],'Built':[],'Expanded':[],'Surface':[]}
for trs in trls:
    tdlst = trs.find_all("td")
    for i, tds in enumerate(tdlst):
        this = tds.text.strip()
        if list(stmap.keys())[i] == "Capacity":
            ## regex to remove commas and citation references
            this = re.sub("[^0-9\[]","",this)
            this = re.sub("\[\d*","",this)
            this = int(this)
        stmap[list(stmap.keys())[i]].append(this)



##----------------------------------------------------------------------------
# revenue from contributions
        


df_rev = pd.read_csv("revenues.tsv", delimiter="\t")
df_rev.columns
df_rev.shape

## only looking at revenues for schools in FBS
df_rev_2 = df_rev.iloc[[x for x in range(df_rev.shape[0]) if df_rev.loc[x,"conf"] in df1_conf],:]
df_rev_2.shape
df_rev_2.reset_index(inplace=True, drop=True)

df_rev_bd = pd.read_csv("rev_breakdown.tsv", delimiter="\t")
df_rev_bd.columns
df_rev_bd.shape

## only looking at contributions made for the 2017 season
df_rev_bd_17 = df_rev_bd[df_rev_bd["YEAR"] == 2017]
df_rev_bd_17.reset_index(inplace=True, drop=True)
df_rev_bd_17.shape

## matches school and their 2017 contribution
contrmap = {}
for i in range(df_rev_2.shape[0]):
    contrmap[df_rev_2.loc[i,"school"]] = int(re.sub("[^0-9]","",df_rev_bd_17.loc[i,"CONTRIBUTIONS"]))
#-------------------------------------------------------------------------------
    ## schools.tsv takes the school list for each source and matches them in the same row
    ## necessary due to different naming schemes: NCAA - North Carolina State University, USATODAY - North Carolina State, Wikipedia - NC State
## this exercise was done manually by printing school names from the various sources. 
sch_ls = pd.read_csv("schools.tsv", delimiter="\t")
sch_ls.columns
#---------------------------------------------------------------------------------------
## combines the various data frames and lists into one entity. 
finallod = []
gradcols = ['FED_N_SA', 'FED_RATE_SA', 'GSR_N_SA', 'GSR_SA',
       'FED_RATE_MALE_AA_SA', 'FED_RATE_MALE_OTHER_SA', 'FED_RATE_MALE_WH_SA',
       'GSR_MALE_AA_SA', 'GSR_MALE_OTHER_SA', 'GSR_MALE_WH_SA',
       'FED_N_2006_SA', 'FED_RATE_2006_SA', 'GSR_N_2006_SA', 'GSR_2006_SA',
       'FED_RATE_MALE_2006_SA', 'GSR_MALE_2006_SA', 'FED_RATE_2006_SB',
       'FED_RATE_MALE_2006_SB']

## easier to access the capacity using a list of (team, capacity) tuples
thisstdls = list(zip(stmap["Team"], stmap["Capacity"]))
for rows1 in sch_ls.iterrows():
    rows = rows1[1]
    if rows["sal_names"] not in contrmap and rows["sal_names"] != "Syracuse":
        continue
    thismap = {"name":rows["sal_names"],"salary": int(df_coaches.loc[df_coaches["School"] == rows["sal_names"],"TotalPay"])}
    for conf in df1_conf:
        thistitle = "member_of" + conf
        if conf == df_coaches.loc[df_coaches["School"] == rows["sal_names"],"Conference"].iloc[0]:
            thismap[thistitle] = 1
        else:
            thismap[thistitle] = 0
    for x in gradcols:
        this = df_gr4.loc[df_gr4["SCL_NAME"]==rows["grad_names"],x]
        if len(this) > 0 and ~np.isnan(float(this)):
            thismap[x] = int(this)
    if len([x for x in range(len(thisstdls)) if thisstdls[x][0] == rows["stadium_names"].strip()]) > 0:
        thismap["stad_size"] = thisstdls[[x for x in range(len(thisstdls)) if thisstdls[x][0] == rows["stadium_names"].strip()][0]][1]
    if rows["sal_names"] != "Syracuse":
        thismap["2017contr"] = int(contrmap[rows["sal_names"]])
    else:#private schools already excluded. This is only for Syracuse
        thismap["2017contr"] = np.mean(list(contrmap.values()))
    finallod.append(thismap)
    


#------------------------------------------------------------------------------
finaldf = pd.DataFrame(finallod, columns = list(finallod[0].keys()))    
finaldf.shape
finaldf.columns

## various visual looks
plt.hist(finaldf["salary"])
plt.hist(finaldf["stad_size"])
plt.hist(finaldf["2017contr"])

plt.scatter(finaldf["2017contr"], finaldf["salary"])
plt.scatter(finaldf["stad_size"],finaldf["salary"])

plt.scatter(finaldf["stad_size"], finaldf["2017contr"])
plt.scatter(finaldf["GSR_2006_SA"], finaldf["2017contr"])


plt.scatter(finaldf["GSR_SA"], finaldf["stad_size"])
plt.scatter(finaldf["GSR_2006_SA"], finaldf["salary"])
plt.scatter(finaldf["GSR_MALE_2006_SA"], finaldf["salary"])
plt.scatter(finaldf["GSR_MALE_AA_SA"], finaldf["salary"])

plt.scatter(finaldf["FED_RATE_SA"], finaldf["salary"])
plt.scatter(finaldf["FED_RATE_2006_SA"], finaldf["salary"])

#------------------------------------------------------------------------------
#based on example at https://scikit-learn.org/stable/auto_examples/linear_model/plot_ols.html
from sklearn import linear_model
from sklearn.metrics import mean_squared_error, r2_score

regr = linear_model.LinearRegression()
regr2 = linear_model.LinearRegression(normalize=True)

## military schools FGR not included. use all variables and remove those rows. 
removefornan = ["Army","Navy","Air Force"]
## use all rows and remove columns with missing data
removeforall = [0,1,13,14,17,18,19,23,24,27,29,30]
## not looking to test accuracy on new data
## simply looking to test the overall amount of variance explained by these variables
holdoutsyr = [x for x in range(finaldf.shape[0]) if finaldf.loc[x,"name"] != "Syracuse"]
holdoutnan = [x for x in range(finaldf.shape[0]) if finaldf.loc[x,"name"] != "Syracuse" and finaldf.loc[x,"name"] not in removefornan]
syracuse = [x for x in range(finaldf.shape[0]) if finaldf.loc[x,"name"] == "Syracuse"]

X_train1 = finaldf.iloc[holdoutsyr,[x for x in range(finaldf.shape[1]) if x not in removeforall]] 
y_train1 = finaldf.loc[holdoutsyr,"salary"]

X_train2 = finaldf.iloc[holdoutnan,2:]
y_train2 = finaldf.loc[holdoutnan,"salary"]



regr.fit(X=X_train1,y=y_train1)
regr2.fit(X=X_train2,y=y_train2)

y_pred1 = regr.predict(X_train1)
y_pred2 = regr2.predict(X_train2)

print('Coefficients: \n', regr.coef_)
for i,x in enumerate(regr.coef_):
    print(finaldf.columns[[x for x in range(finaldf.shape[1]) if x not in removeforall][i]], x)
# The mean squared error
print("Mean squared error: %.2f"
      % mean_squared_error(y_train1, y_pred1))
# Explained variance score: 1 is perfect prediction
print('Variance score: %.2f' % r2_score(y_train1, y_pred1))

## plots the predicted salaries against the actual salaries. Syr is the green x. 
## red line is simply y=x. All points on that line means R2 = 1
plt.scatter(y_train1, y_pred1, color='blue')
plt.plot([0,8000000], [0,8000000], color="red", linewidth=2)
plt.plot(finaldf.loc[syracuse,"salary"], regr.predict(finaldf.iloc[syracuse,[x for x in range(finaldf.shape[1]) if x not in removeforall]]), marker="x", color="green", markersize=10)

for i,x in enumerate(regr2.coef_):
    print(finaldf.columns[i+2], x)

print('Coefficients: \n', regr2.coef_)
# The mean squared error
print("Mean squared error: %.2f"
      % mean_squared_error(y_train2, y_pred2))
# Explained variance score: 1 is perfect prediction
print('Variance score: %.2f' % r2_score(y_train2, y_pred2))

plt.scatter(y_train2, y_pred2, color='blue')
plt.plot([0,8000000], [0,8000000], color="red", linewidth=2)
plt.plot(finaldf.loc[syracuse,"salary"], regr2.predict(finaldf.iloc[syracuse,2:]), marker="x", color="green", markersize=10)

#--------------------------------------------------------------------------------

## too look at variable impact, the previous models must be ran again with standardized data. 
for x in finallod[0]:
    if type(finallod[0][x]) == int and "member" not in x:
        average = np.mean([finallod[j][x] for j in range(len(finallod)) if x in finallod[j]])
        sd = np.std([finallod[j][x] for j in range(len(finallod)) if x in finallod[j]])
        print(x, average, sd)
        for row in finallod:
            if x in row:
                row[x] = (row[x] - average)/sd
finaldf2 = pd.DataFrame(finallod, columns = list(finallod[0].keys()))

y_train3 = finaldf2.loc[holdoutnan,"salary"]
regr3 = linear_model.LinearRegression(normalize=True)
X_train3 = finaldf2.iloc[holdoutnan,31:33]
regr3.fit(X=X_train3,y=y_train3)
y_pred3 = regr3.predict(X_train3)



print('Coefficients: \n', regr3.coef_)
# The mean squared error
print("Mean squared error: %.2f"
      % mean_squared_error(y_train3, y_pred3))
# Explained variance score: 1 is perfect prediction
print('Variance score: %.2f' % r2_score(y_train2, y_pred3))

plt.scatter(y_train3, y_pred3, color='blue')
plt.plot([-3,3], [-3,3], color="red", linewidth=2)
plt.plot(finaldf.loc[syracuse,"salary"], regr.predict(finaldf2.iloc[syracuse,[x for x in range(finaldf.shape[1]) if x not in removeforall]]), marker="x", color="green", markersize=10)

regr4 = linear_model.LinearRegression(normalize=True)
X_train4 = finaldf2.iloc[holdoutnan,2:]
regr4.fit(X=X_train4,y=y_train3)
y_pred4 = regr4.predict(X_train4)

for i,x in enumerate(regr4.coef_):
    print(i+2,finaldf.columns[i+2], x)

print('Coefficients: \n', regr4.coef_)
# The mean squared error
print("Mean squared error: %.2f"
      % mean_squared_error(y_train3, y_pred4))
# Explained variance score: 1 is perfect prediction
print('Variance score: %.2f' % r2_score(y_train3, y_pred4))

plt.scatter(y_train3, y_pred4, color='blue')
plt.plot([-3,3], [-3,3], color="red", linewidth=2)
plt.plot(finaldf2.loc[syracuse,"salary"], regr2.predict(finaldf2.iloc[syracuse,2:]), marker="x", color="green", markersize=10)

#------------------------------------------------------------------------------

## answers the questions for a hypothetical new Syracuse head coach. 
##Checks for our conference being ACC, AAC (Formerly Big East) and Big Ten
## uses regression 2 non standardized data to make predictions. 
syracuse_ch = finaldf.iloc[syracuse,:]
testchanges = ["member_ofAAC", "member_ofBig Ten"]
print(regr2.predict(finaldf.iloc[syracuse,2:]))
syracuse_ch.loc[syracuse[0],"member_ofACC"] = 0
for i in range(syracuse_ch.shape[1]):
    #print(syracuse_ch.iloc[0,i])
    if syracuse_ch.columns[i] in testchanges:
        print(syracuse_ch.columns[i])
        print(syracuse_ch.loc[syracuse[0],syracuse_ch.columns[i]])
        syracuse_ch.loc[syracuse[0],syracuse_ch.columns[i]] = 1
        print(syracuse_ch.loc[syracuse[0],syracuse_ch.columns[i]])
        print(regr2.predict(syracuse_ch.iloc[0,2:].values.reshape(1,-1)))
        syracuse_ch.loc[syracuse[0],syracuse_ch.columns[i]] = 0
#------------------------------------------------------------------------------

