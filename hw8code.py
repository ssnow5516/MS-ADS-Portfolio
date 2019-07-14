# -*- coding: utf-8 -*-
"""
Created on Sun Mar 10 15:20:42 2019

@author:  Scott Snow
"""

import matplotlib.pyplot as plt
import re
import pandas as pd
import os.path

keysfile = "homework_8_data/110/110keys2.txt"

docsfile = "homework_8_data/110/110docs2.txt"

keywords = []
topictitles = []
weights = []
with open(keysfile, "rU") as keys:
    for line in keys:
        this = line.split("//")
        topictitles.append(this[1].strip())
        this2 = this[0].split("\t")
        weights.append(float(this2[1]))
        for word in this2[2].split(" "):
            keywords.append(word)
            
## bar graph of topics and weights

   

docsdf = pd.read_csv(docsfile, sep='\t')

docsdf.columns = ["filename",] + topictitles
## for each document, we get the number of fem-dem, fem-rep, m-dem, m-rep speakers
myfilepath = "E:/Documents/School2019/SU_ADS_January_2019_Term/IST736/pythoncode/hwcode/homework_8_data/110/"
groups = ["110-f-d", "110-f-r", "110-m-d", "110-m-r"]
topicspeakers = {}
maxvals = []
grpttls = {}
for rows in docsdf.iterrows():
    thiscol = [docsdf.columns[i] for i in range(len(docsdf.columns)) if rows[1][i] == max(rows[1][1:])][0]
    thisfile = rows[1][0]
    maxvals.append(max(rows[1][1:]))
    if thiscol not in topicspeakers:
        topicspeakers[thiscol] = {}
    for cats in groups:
        thisfile = myfilepath + cats + "/" + re.findall("[ \w-]+?(?=\.)",thisfile)[0] + ".txt"
        if os.path.isfile(thisfile):
            if cats in topicspeakers[thiscol]:
                topicspeakers[thiscol][cats] += 1
            else:
                topicspeakers[thiscol][cats] = 1
            if cats in grpttls:
                grpttls[cats] += 1
            else:
                grpttls[cats] = 1
                
fig, hist = plt.subplots()
hist.hist(maxvals)
hist.set_title("Histogram of Max Liklihoods for Each Topic/Document Combination")

fig, pie1 = plt.subplots()
pie1.pie(list(grpttls.values()), labels=grpttls.keys())
pie1.set_title("Document Breakdown by Speaker Grouping")
print(sum(list(grpttls.values())))

grpstops = {}
for tops in topicspeakers:
    for grps in topicspeakers[tops]:
        if grps not in grpstops:
            grpstops[grps] = {tops:topicspeakers[tops][grps]}
        else:
            grpstops[grps][tops] = topicspeakers[tops][grps]
            
for grps in grpstops:
    fig, currpie = plt.subplots()
    currpie.pie(list(grpstops[grps].values()), labels = grpstops[grps].keys())
    currpie.set_title("Breakdown of %s by Topic" % grps)


             
