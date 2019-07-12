# -*- coding: utf-8 -*-
"""
Created on Sun Mar 17 14:26:16 2019

@author:  Scott Snow
IST 652 Final Project Code
"""

import urllib.request as req
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from bs4 import BeautifulSoup
import datetime as dt
import calendar
import re
import traceback
d = dict((v,k) for k,v in enumerate(calendar.month_abbr))
from wordcloud import WordCloud
from nltk.corpus import stopwords
set(stopwords.words('english'))


#----------------------------------------------------------------------------
#This first section uses the years between 2002 and 2016 to generate a list of
#rap/hiphop albums released. Only those with their own wikipedia page are included.
# 2017 onward changed the format for document albums released. Each month had their own table
# so those years are ignored. 

years = np.arange(2002,2017,1)
listofalbums = []
for yrs in years:
    try:
        if yrs == years[0]:
            startdate = dt.date(yrs,10,1)
            enddate = dt.date(yrs,12,31)
        elif yrs == years[len(years)-1]:
            startdate = dt.date(yrs,1,1)
            enddate = dt.date(yrs,9,30)
        else:
            startdate = dt.date(yrs,1,1)
            enddate = dt.date(yrs,12,31)
        url = "https://en.wikipedia.org/wiki/" + str(yrs) + "_in_hip_hop_music"
        yrinhp = req.urlopen(url)
        
        html = yrinhp.read().decode('utf8')
        starttable = "id=\"Released_albums\""
        tableonly = ""
        attable = "<table"
        endtbl = "</table>"
        strttbl = False
        nexttbl = False
        for i in range(len(html)):
            try:
                if html[i:i+len(starttable)] == starttable:
                    nexttbl = True
                if html[i:i+len(attable)] == attable and nexttbl:
                    strttbl = True
                if strttbl:
                    tableonly += html[i]
                if html[i-len(endtbl):i] == endtbl:
                    strttbl = False
                    nexttbl = False
            except:
                None
        tablesoup = BeautifulSoup(tableonly, "html.parser")
        l = []
        currentdate = None
        numcols = 0
        isfst = True
        for tr in tablesoup.find_all("tr"):
            td = tr.find_all('td')
            if len(td) == 0:
                continue
            rowlks = [tr.find_all("a") for tr in td]
            rowtxt = [tr.text for tr in td]
            if isfst:
                numcols = len(rowtxt)
                isfst = False
            if len(rowtxt) == numcols:
                thisdate = rowtxt[0]
                thisdate = thisdate.split(" ")
                month = d[thisdate[0][0:3]]
                day = re.sub("\n", "", thisdate[1])
                currentdate = dt.date(yrs,month,int(day))
            if len(rowlks) == numcols:
                rowlks = [currentdate, rowtxt[1], rowlks[2], rowlks[3]]
            elif len(rowlks) == numcols-1:
                rowlks = [currentdate, rowtxt[0], rowlks[1], rowlks[2]]
            elif len(rowlks) > 0:
                rowlks = [currentdate, rowtxt[1], rowlks[0], None]
            l.append(rowlks)
        anchors = pd.DataFrame(l, columns=["release_date", "artist", "album", "label"])
        for i in range(anchors.shape[0]):
            if anchors.loc[i,"release_date"] >= startdate and anchors.loc[i,"release_date"] <= enddate and len(anchors.loc[i,"album"]) > 0:
                listofalbums.append(["https://en.wikipedia.org" + anchors.loc[i,"album"][0]["href"],anchors.loc[i,"artist"].rstrip()])
    except:
        print(yrs)
        traceback.print_exc()
        
#--------------------------------------------------------------------------------------  
# from the album list, this section generates a list of songs. 
        
listofsongs = []
badtablecount = 0
for alb in listofalbums:
    try:
        albpg = req.urlopen(alb[0])
        html = albpg.read().decode('utf8')
    
        htmlsoup = BeautifulSoup(html, "html.parser")
        tableonly = htmlsoup.find_all("table", {"class":"tracklist"})
        if len(tableonly) == 0:
            tableonly = htmlsoup.find_all("table", {"id":"Track_listing"})
        l = []
        numcols = 0
        isfst = True
        for tr in tableonly[0].find_all("tr"):
            td = tr.find_all('td')
            if len(td) == 0:
                continue
            rowlks = [tr.find_all("a") for tr in td]
            rowtxt = [tr.text for tr in td]
            #print(rowlks)
            rowtitle = re.findall(r'"(.*?)"', rowtxt[1])[0]
            if isfst:
                numcols = len(rowtxt)
                isfst = False
            for a in rowlks[1]:
                thistitle = re.sub("\s(\(.+\))", "", a["title"])
                if thistitle == re.sub("\s(\(.+\))", "", rowtitle):
                    l.append([a["href"], rowtxt[numcols-2], rowtxt[numcols-1], rowtitle])
                    
        for rows in l:
            time = rows[2].split(":")
            seconds = int(time[0]) * 60 + int(time[1])
            listofsongs.append([alb[1],rows[3],"https://en.wikipedia.org" + rows[0], rows[1].rstrip().split(","), seconds])
    except:
        badtablecount += 1
      #  traceback.print_exc()

#-----------------------------------------------------------------------------------  
# This section gained additional information for each song to complete them for the next section
grmdf = pd.read_csv("projectgrammycustom.csv")

songsfinal = []
for songs in listofsongs:
    try:
        songpg = req.urlopen(songs[2])
    except:
        print(songs[2])
    html = songpg.read().decode('utf8')
    htmlsoup = BeautifulSoup(html, "html.parser")
    
    nexttr = False
    songwriters = []
    for tr in htmlsoup.find_all("tr"):
        try:
            if "Songwriter" in [tr.find_all("a")[x]["title"] for x in range(len(tr.find_all("a")))]:
                for anch in tr.find_all("a")[1:]:
                    songwriters.append(anch.text)
        except:
            None
    songsfinal.append([songs,songwriters])

for rows in grmdf.iterrows():
    if rows[1]["link"] not in [listofsongs[x][2] for x in range(len(listofsongs))]:
        
        songpg = req.urlopen(rows[1]["link"])
        html = songpg.read().decode('utf8')
        htmlsoup = BeautifulSoup(html, "html.parser")
    
        producers = []
        for tr in htmlsoup.find_all("tr"):
            try:
                if "Record producer" in [tr.find_all("a")[x]["title"] for x in range(len(tr.find_all("a")))]:
                    for anch in tr.find_all("a")[1:]:
                        producers.append(anch.text)
                    for li in tr.find_all("li")[1:]:
                        producers.append(li.text)
            except:
                None
        go = True
        dur = 0
        for spans in htmlsoup.find_all("span", {"class":"duration"}):
            if go:
                time = spans.text.split(":")
                dur = int(time[0])*60 + int(time[1])
                go = False
        songsfinal.append([rows,producers,dur])

#-------------------------------------------------------------------------------
## This section has all of the pertinent information. It seeks to generate a list 
## of all the producers, all the songwriters and all the words used. 
    
allwriters = []
allprod = []
alllyrics = []
alllyricsnoms = []
alllyricswins = []
omittedct = 0
fxurls = pd.read_csv("fixedurls.csv")
for songs in songsfinal:
    nom = False
    win = False
    if type(songs[0]) == tuple:
        for prod in songs[1]:
            if prod not in allprod and len(prod) > 1:
                allprod.append(prod)
        for writ in songs[0][1]["songwriters"]:
            if writ not in allwriters and len(writ) > 1:
                allwriters.append(writ)
        thisartist = re.sub(" ", "-", songs[0][1]["artists"].split(",")[0])
        thissong = re.sub(" ", "-", songs[0][1]["title"])
        if songs[0][1][5] == 1:
            win = True
        else:
            nom = True
    else:
        for prod in songs[0][3]:
            if prod not in allprod and len(prod) > 1:
                allprod.append(prod)
        for writ in songs[1]:
            if writ not in allwriters and len(writ) > 1:
                allwriters.append(writ)
        thisartist = re.sub(" ", "-", songs[0][0])
        thissong = re.sub(" ", "-", songs[0][1])
    if thisartist == "Pharrell" or thisartist == "The-Neptunes":
        thisartist = "Pharrell-williams"
    comb = thisartist + "-" + thissong
    comb = re.sub("[^a-zA-Z0-9\-]*", "", comb)
    comb = re.sub("--","-",comb)
    url = "https://genius.com/" + comb.capitalize() + "-lyrics"
    try:
        try:
            # requires user-agent headers per their scraping protocal
            connect = req.Request(url, data=None, headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'})
            lyricpg = req.urlopen(connect)
        except:
            url = [fxurls.loc[x,"goodurl"] for x in range(fxurls.shape[0]) if url == fxurls.loc[x,"badurl"]]
            connect = req.Request(url[0], data=None, headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'})
            lyricpg = req.urlopen(connect)
        html = lyricpg.read().decode('utf8')
        htmlsoup = BeautifulSoup(html, "html.parser")
        
        lyrics = htmlsoup.find("div", {"class":"lyrics"}).text
        alllyrics.append([thisartist,thissong,lyrics])
        if win:
            alllyricswins.append([thisartist,thissong,lyrics])
        elif nom:
            alllyricsnoms.append([thisartist,thissong,lyrics])
    except:
        omittedct += 1
        print(omittedct)
#--------------------------------------------------------------------------------
## attempt to clean up the list of producers. Some imrovement but still not enough
newprodls = []
for prod in allprod:
    curr = prod.split(",")
    for this in curr:
        this = re.sub("\s(\(.+\))", "", prod) # removes paranthesis and inner text
        this = re.sub(r'"(.*?)"',"",this) # removes quotes and inner text
        this = re.sub("–.*", "", this) # removes long dash and following text
        this = re.sub("-\s.*", "", this) # removes short dashes followed by space and the remaining text
        this = re.sub("^[a-z].*","",this) # replaces lines that don't start with a captial letter with an empty line
        this = re.sub("\\n", "", this) # removes new line characters that are inside the string
        this = re.sub("\[.*\]","",this) # removes brackets and any text inside of them. 
        if len(this) > 0:
            newprodls.append(this.lstrip())
newprodls
#--------------------------------------------------------------------------------
## This section tokenizes the lyrics for visualization purposes
lyricsets = [alllyrics,alllyricsnoms,alllyricswins]
wordlists = []
stop_words = set(stopwords.words('english'))
for sets in lyricsets:
    wordset = []
    for songs in sets:
        curr = songs[2].split(" ")
        for words in curr:
            thwrd = words.rstrip()
            thwrd = words.lstrip()
            thwrd = words.strip()
            thwrd = re.sub("[^a-zA-Z]*", "", thwrd)
            if thwrd not in stop_words:
                wordset.append(thwrd)
    wordlists.append(wordset)

## this section saves three word clouds that show the most popular terms. 
for i,grps in enumerate(wordlists):
    wordcloud = WordCloud(max_font_size=50, max_words=30, background_color="black").generate(" ".join(grps))
    # Open a plot of the generated image.
    
    plt.figure(figsize=(50,40))
    plt.imshow(wordcloud)
    plt.axis("off")
    plt.savefig("wc" + str(i) + ".png")
        
for x in wordlists:
    print(len(x))
proddict = {}
for prod in allprod:
    prod = re.sub("[^a-zA-Z]*", "", prod)
    if prod in proddict:
        proddict[prod] += 1
    else:
        proddict[prod] = 1
      
writdict = {}
allwriters2 = []
for writs in allwriters:
    this = writs.split(",")
    for writ in this:
        writ = re.sub("[^a-zA-Z\s]*", "", writ)
        writ.replace(u'\xa0', ' ').encode('utf-8')
        writ = writ.lstrip()
        if writ in writdict:
            writdict[writ] += 1
        else:
            writdict[writ] = 1
        allwriters2.append(writ)
    
with open("writout.txt", "w") as writout:
    for writ in allwriters2:
        writout.write(writ)
        writout.write("\n")
        

worddicts = []
for wrd in wordlists:
    wd1 = {}
    for words in wrd:
        if words in wd1:
            wd1[words] += 1
        else:
            wd1[words] = 1
    worddicts.append(wd1)
    
for d in worddicts:
    print(len(d.keys()))
    
##------------------------------------------------------------------------------
## this section creates the pieces necessary for a basic SVM model   
    
nomsbin = []
winsbin = []    
for songs in alllyrics:
    if songs[1] in [alllyricsnoms[x][1] for x in range(len(alllyricsnoms))]:
        nomsbin.append(1)
    else:
        nomsbin.append(0)
    if songs[1] in [alllyricswins[x][1] for x in range(len(alllyricswins))]:
        winsbin.append(1)
    else:
        winsbin.append(0)
nomsbin2 = []
for i in range(len(nomsbin)):
    nomsbin2.append(nomsbin[i] + winsbin[i])
    
from sklearn.feature_extraction.text import CountVectorizer

unigram_count_vectorizer = CountVectorizer(encoding='latin-1', token_pattern=r'[A-Za-z0-9]{2,}', binary=False, min_df=5, stop_words='english')

holdoutperc = .5
holdoutind = round((len(winsbin) * holdoutperc))
permnums = np.random.permutation(range(len(winsbin)))
lyricstrain = [alllyrics[x][2] for x in permnums[:holdoutind]]
y_train_noms = [nomsbin2[x] for x in permnums[:holdoutind]]
y_test_noms = [nomsbin2[x] for x in permnums[holdoutind:]]
y_train_wins = [winsbin[x] for x in permnums[:holdoutind]]
y_test_wins = [winsbin[x] for x in permnums[holdoutind:]]
lyricstest = [alllyrics[x][2] for x in permnums[holdoutind:]]
X_train_vec = unigram_count_vectorizer.fit_transform(lyricstrain)
X_test_vec = unigram_count_vectorizer.transform(lyricstest)

## the first ten features
print(list(unigram_count_vectorizer.vocabulary_.items())[:10])
#------------------------------------------------------------------------------
## applies the SVM model to predicting nominations
from sklearn.svm import LinearSVC

svm_clf = LinearSVC(C=1, max_iter = 2000)

# use the training data to train the model
y_pred_svm = svm_clf.fit(X_train_vec,y_train_noms)

from sklearn.metrics import confusion_matrix
y_pred_svm = svm_clf.predict(X_test_vec)
cm_svm=confusion_matrix(y_test_noms, y_pred_svm, labels=[0,1])
print(cm_svm)
print()

from sklearn.metrics import classification_report
target_names = ['0','1']
print(classification_report(y_test_noms, y_pred_svm, target_names=target_names))

#------------------------------------------------------------------------------
## applies the SVM model to predicing wins from all objects.
svm_clf2 = LinearSVC(C=1, max_iter = 3000)

# use the training data to train the model
y_pred_svm2 = svm_clf2.fit(X_train_vec,y_train_wins)

y_pred_svm2 = svm_clf2.predict(X_test_vec)
cm_svm2=confusion_matrix(y_test_wins, y_pred_svm2, labels=[0,1])
print(cm_svm2)
print()

target_names = ['0','1']
print(classification_report(y_test_wins, y_pred_svm2, target_names=target_names))
#--------------------------------------------------------------------------------
## uses only nominated songs as a training set to make predicitons for wins
newtrainind = [x for x in range(0,len(nomsbin2)) if nomsbin2[x] == 1]
unigram_count_vectorizer = CountVectorizer(encoding='latin-1', token_pattern=r'[A-Za-z0-9]{2,}', binary=False, min_df=5, stop_words='english')

winsbin2 = [winsbin[x] for x in newtrainind]
nomlyronly = [alllyrics[x][2] for x in newtrainind]

holdoutperc = .5
holdoutind = round((len(winsbin2) * holdoutperc))
permnums2 = np.random.permutation(range(len(winsbin2)))

lyricstrain = [nomlyronly[x] for x in permnums2[:holdoutind]]
y_train = [winsbin2[x] for x in permnums2[:holdoutind]]
y_test = [winsbin2[x] for x in permnums2[holdoutind:]]
lyricstest = [nomlyronly[x] for x in permnums2[holdoutind:]]
X_train_vec = unigram_count_vectorizer.fit_transform(lyricstrain)
X_test_vec = unigram_count_vectorizer.transform(lyricstest)
#-------------------------------------------------------------------------------
## the svm model to predict wins from nominees only. 
svm_clf3 = LinearSVC(C=1, max_iter = 2000)

# use the training data to train the model
y_pred_svm3 = svm_clf3.fit(X_train_vec,y_train)

y_pred_svm3 = svm_clf3.predict(X_test_vec)
cm_svm3=confusion_matrix(y_test, y_pred_svm3, labels=[0,1])
print(cm_svm3)
print()

target_names = ['0','1']
print(classification_report(y_test, y_pred_svm3, target_names=target_names))


#--------------------------------------------------------------------------------
## performs analsysis and visualizations on the data containted in the custom csv. 
nomwrit = {}
nomwritpairs = {}
for rows in grmdf.iterrows():
    writers = rows[1][1].split(",")
    pairs = []
    if len(writers) > 1:
        for i in range(len(writers) - 1):
            for j in np.arange(i + 1,len(writers) - 1,1):
                pairs.append((writers[i], writers[j]))
    for writ in writers:
        if writ in nomwrit:
            nomwrit[writ] += 1
        else:
            nomwrit[writ] = 1
    for prs in pairs:
        if prs in nomwritpairs:
            nomwritpairs[prs] += 1
        else:
            nomwritpairs[prs] = 1
            
print(len(nomwrit))
ct = 1
forgraph = []    
for x in nomwrit:
    if nomwrit[x] > 3:
        forgraph.append([ct, x, nomwrit[x]])
        ct += 1
        
fig, writbar = plt.subplots()
writbar.bar(x=[forgraph[x][0] for x in range(len(forgraph))], height=[forgraph[x][2] for x in range(len(forgraph))], width=.85)
writbar.set_xticks(np.arange(2,len(forgraph)+2,1))
writbar.set_xticklabels(labels = [forgraph[x][1] for x in range(len(forgraph))], rotation=-45)
writbar.set_title("Most Frequently Credited Song Writers among All Nominees; Freq > 3")

print(len(nomwritpairs))
ct = 1
forgraphpairs = []    
for x in nomwritpairs:
    if nomwritpairs[x] > 2:
        forgraphpairs.append([ct, x, nomwritpairs[x]])
        ct += 1
        
fig, writpairsbar = plt.subplots()
writpairsbar.bar(x=[forgraphpairs[x][0] for x in range(len(forgraphpairs))], height=[forgraphpairs[x][2] for x in range(len(forgraphpairs))], width=.85)
writpairsbar.set_xticks(np.arange(2,len(forgraphpairs)+2,1))
writpairsbar.set_xticklabels(labels = [forgraphpairs[x][1] for x in range(len(forgraphpairs))], rotation=-45)
writpairsbar.set_title("Most Frequently Credited Songwriting Pairs among All Nominees; Freq > 2")
    

