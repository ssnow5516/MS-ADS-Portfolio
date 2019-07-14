#Final Project IST 687 Summer 2018
#Scott Snow, Jeffrey Kao, Kendra Osburn, Benjamin Schneider

#ensure required libraries

EnsurePackage <- function(x) {
  x <- as.character(x)
  
  if (!require(x, character.only=TRUE)) {
    install.packages(pkgs=x, repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
    
  }
}
# get packages
EnsurePackage("dplyr")
EnsurePackage("sqldf")
EnsurePackage("ggplot2")
EnsurePackage("kernlab")
EnsurePackage("gdata")
EnsurePackage("ggmap")
EnsurePackage("scatterplot3d")
library(dplyr)
library(sqldf)
library(ggplot2)
library(kernlab)
library(gdata)
library(ggmap)
library(scatterplot3d)
#-------------------------------------------------------------------------------
# get csv
urlToRead <- "https://trello-attachments.s3.amazonaws.com/5b6dc416cb77f61d2d3919d7/5b6dc416e8e0a46275da92ef/24742472ff3d38988c48f004878be4d5/NBASeasonData1978-2016.csv"
# Read CSV
csv <- read.csv(url(urlToRead), header=TRUE, sep=",")
# Keep only rows from 2005-2015
nba <- csv[11083:16859, ]
# Convert to dataframe
nbadf <- as.data.frame(nba)
# Select columns needed
nbadfselected <- nbadf %>% select("Year",
                         "Tm",
                         "Player",
                         "Age",
                         "G",
                         "MP",
                         "PER",
                         "TS.",
                         "X3PAr",
                         "FTr",
                         "ORB.",
                         "DRB.",
                         "TRB.",
                         "AST.",
                         "BLK.",
                         "TOV.",
                         "USG.",
                         "OWS",
                         "DWS",
                         "WS",
                         "WS.48",
                         "OBPM",
                         "DBPM",
                         "BPM",
                         "VORP",
                         "OWS.48",
                         "DWS.48",
                         "Shot.",
                         "Team.MP",
                         "Year.3PAr",
                         "Team.TS.",
                         "Tm.TS.W.O.Plyr",
                         "TrueSalary",
                         "Estimated.Position",
                         "Rounded.Position",
                         "Height",
                         "Weight",
                         "Yrs.Experience")

# Rename columns
colnames(nbadfselected) <- c("Year", "Team", "Player Name", 
                             "Age", "Games Played", "Minutes Played",
                             "Player Efficiency Rating", "True Shooting %",
                             "3Pt Attempt Rate", "FT Attempt Rate",
                             "Offensive Rebound %", "Defensive Rebound %",
                             "True Rebound %", "Assist %", "Block %", 
                             "Turnover %", "Usage %", "Offensive Win Shares",
                             "Defensive Win Shares", "Win Shares",
                             "Win Shares Per 48min", "Offensive Box +/-",
                             "Defensive Box +/-", "Box +/-",
                             "Value over Replacement Player", "Offensive Win Shares Per 48min",
                             "Defensive Win Shares Per 48min", "% Shots of Team",
                             "Team Minutes Played", "Year 3Pt Attempt Rate",
                             "Team True Shooting %", "Team True Shooting % w/o Player",
                             "True Salary","Estimated Position", 
                             "Rounded Position", "Height", "Weight", "Years Experience")

# remove blank True salaries
nbadfselected <- nbadfselected %>% filter(`True Salary`!="")
# should get 4169 obs. of 38 variables.

# replaces team names with their current team name
# i.e. a team changed their name or moved locations or both
tempteamnames <- as.character(nbadfselected$Team)
for (i in seq(1:length(tempteamnames))) {
  if(tempteamnames[i] == "SEA") {
    tempteamnames[i] <- "OKC"
  }
  if(tempteamnames[i] == "NJN") {
    tempteamnames[i] <- "BRK"
  }
  if(tempteamnames[i] == "CHA" || tempteamnames[i] == "CHH"){
    tempteamnames[i] <- "CHO"
  }
  if(tempteamnames[i] == "NOK" || tempteamnames[i] == "NOH"){
    tempteamnames[i] <- "NOP"
  }
}
nbadfselected$Team <- as.factor(tempteamnames)

#quick csv containing nba champs, runner ups and the years MVP
urlToRead2 <- "https://trello-attachments.s3.amazonaws.com/5b6dc416cb77f61d2d3919d7/5b6dc416e8e0a46275da92ef/31892bb2bbc23a8c996972b0285f4434/smalltable.csv"
smallcsv <- read.csv(url(urlToRead2), header=TRUE, sep=",")

#creates new columns
nbadfselected$'Championship Team' <- NULL
nbadfselected$'Runner Up' <- NULL
nbadfselected$'MVP' <- NULL

# contains 1 if that player played in the finals or was the mvp respectively
for(j in seq(1:length(nbadfselected$Year))){
  nbadfselected$'Championship Team'[j] <- 0
  nbadfselected$'Runner Up'[j] <- 0
  nbadfselected$'MVP'[j] <- 0
  for (i in seq(1:length(smallcsv$Year))) {
    if(nbadfselected$Year[j] == smallcsv$Year[i]) {
      if(nbadfselected$'Team'[j] == smallcsv$NBA.Champion[i]){
        nbadfselected$'Championship Team'[j] <- 1
      }  
      if(nbadfselected$'Team'[j] == smallcsv$NBA.Runner.Up[i]){
        nbadfselected$'Runner Up'[j] <- 1
      }
      if(nbadfselected$`Player Name`[j] == smallcsv$MVP[i])
      nbadfselected$'MVP'[j] <- 1
    }
  }
}

#convert True Salary to Numeric
temp <- as.character(nbadfselected$`True Salary`)
temp <- gsub("\\$", "", temp)
temp <- gsub(",", "", temp)
temp <- as.numeric(temp)
nbadfselected$`True Salary` <- temp

#convert both position columns, height, weight and years experience to numeric
nbadfselected$`Estimated Position` <- as.numeric(as.character(nbadfselected$`Estimated Position`))
nbadfselected$`Rounded Position` <- as.numeric(as.character(nbadfselected$`Rounded Position`))
nbadfselected$Height <- as.numeric(as.character(nbadfselected$Height))
nbadfselected$Weight <- as.numeric(as.character(nbadfselected$Weight))
nbadfselected$`Years Experience` <- as.numeric(as.character(nbadfselected$`Years Experience`))

#retrieval function that will be used later
getSTAT <- function(player, year, stat) {
  index <- which(match(nbadfselected$`Player Name`, player) == match(nbadfselected$`Year`, year))
  return(mean(nbadfselected[index, which(match(colnames(nbadfselected), stat) == 1)]))
}
#ensures the team and player are characters not factors
nbadfselected$`Player Name` <- as.character(nbadfselected$`Player Name`)
nbadfselected$Team <- as.character(nbadfselected$Team)

#creates an "average" replacement player to test a teams performance without a star player for each year
years <- unique(nbadfselected$Year)
avgplayersdf <- data.frame()

for(j in years) {
  avgplayer <- c(j,"AVG","Average Player")
  for(i in 4:dim(nbadfselected)[2]) {
    avg <- as.numeric(sum(nbadfselected[nbadfselected$Year == j,i])/dim(nbadfselected[nbadfselected$Year == j,])[1])
    if(i > 38) {
      avg <- 0
    } else if (i > 35) {
      avg <- round(avg)
    } else if(i == 35) {
      avg <- 0
    }
    avgplayer <- c(avgplayer, avg)
  }
  avgplayersdf <- rbind.data.frame(avgplayersdf, as.numeric(avgplayer))
  #print(avgplayersdf)
}
colnames(avgplayersdf) <- colnames(nbadfselected)
avgplayersdf$Team <- "AVG"
avgplayersdf$`Player Name` <- "Average Player"

nbadfselected <- rbind.data.frame(nbadfselected, avgplayersdf)

#descriptive statistics
round(sapply(nbadfselected[,4:38], mean), digits=3)
round(sapply(nbadfselected[,4:38], median), digits=3)

#exporting cleaned data to csv
setwd("~/Desktop")
write.csv(nbadfselected,'nbadata.csv')
#-------------------------------------------------------------------
#str(nbadfselected)
#calculates the average teamsize(30 teams in the nba)
teamsize <- floor(mean(as.numeric(unlist(sqldf("SELECT Year, COUNT(Team)/30 FROM nbadfselected GROUP BY Year ")[2]))))
totalteams <- 30

getfinalsample <- function(samplesize, stat1, stat2) {
# gets the number of 
  fantasyyears <- replicate(samplesize, sample(years, 1), simplify=TRUE)
  fantasyteams <- data.frame(nextCol=vector(length = 11))
  for(i in 1:samplesize) {
    thisyear <- fantasyyears[i]
    thisteam <- NULL
    positionbins <- unlist(fn$sqldf("SELECT COUNT([Rounded Position]) AS Bin FROM nbadfselected WHERE Year = $thisyear GROUP BY [Rounded Position]"))
    for(j in 1:5) {
      positionbins[j] <- round(positionbins[j]/totalteams)
      yearsplayers <- nbadfselected[nbadfselected$Year == fantasyyears[i],]
      thisteam <- c(thisteam, as.character(sample(yearsplayers[yearsplayers$`Rounded Position` == j,]$`Player Name`, positionbins[j])))
    }
    if(dim(fantasyteams)[1] < length(thisteam)) {
      thisteam <- thisteam[1:dim(fantasyteams)[1]]
    } 
    while (dim(fantasyteams)[1] > length(thisteam)) {
      thisteam <- c(thisteam, "Average Player")
    }
    fantasyteams$nextCol <- thisteam
    colnames(fantasyteams)[i] <- as.character(fantasyyears[i])
  }

  fantasystats <- data.frame(row.names = sprintf("Team %d", seq(1:samplesize)))
  for(i in 1:ncol(fantasyteams)) {
    sumchampsorrun <- 0
    AVG1 <- 0
    AVG2 <- 0
  Totalwinshares <- 0
  mvpflag <- FALSE
  for(j in 1:nrow(fantasyteams)) {
    if(getSTAT(fantasyteams[j,i], colnames(fantasyteams)[i], "MVP") == 1) {
      mvpflag <- TRUE
    }
    sumchampsorrun <- sumchampsorrun + ceiling(getSTAT(fantasyteams[j,i], colnames(fantasyteams)[i], "Championship Team")) + ceiling(getSTAT(fantasyteams[j,i], colnames(fantasyteams)[i], "Runner Up"))
    AVG1 <- AVG1 + getSTAT(fantasyteams[j,i], colnames(fantasyteams)[i], stat1)
    AVG2 <- AVG2 + getSTAT(fantasyteams[j,i], colnames(fantasyteams)[i], stat2)
    Totalwinshares <- Totalwinshares + getSTAT(fantasyteams[j,i], colnames(fantasyteams)[i], "Win Shares")
  }
  fantasystats <- rbind.data.frame(fantasystats, c(as.integer(colnames(fantasyteams)[i]), mvpflag, sumchampsorrun, AVG1/nrow(fantasyteams), AVG2/nrow(fantasyteams), Totalwinshares))
  }
  colnames(fantasystats) <- c("Year", "Has MVP", "Finalist Total", sprintf("%s Average", stat1), sprintf("%s Average", stat2), "Total Win Shares")
  return(fantasystats)
}

samplestats <- getfinalsample(1000, "True Shooting %", "Usage %")
colnames(nbadfselected)
sqldf("SELECT COUNT(Year) FROM samplestats WHERE [Has MVP] == 1")
percenttop <- quantile(samplestats$`Total Win Shares`, c(0.0, .90, 1))[2]
fn$sqldf("SELECT COUNT(Year) FROM samplestats WHERE [Has MVP] == 1 AND [Total Win Shares] > $percenttop")

maxfinalists <- as.integer(sqldf("SELECT MAX([Finalist Total]) FROM samplestats"))

top5count <- c()
totcount <- c()
for (i in 0:maxfinalists) {
  top5count <- c(top5count, as.numeric(fn$sqldf("SELECT COUNT(Year) FROM samplestats WHERE [Finalist Total] == $i AND [Total Win Shares] > $percenttop")))
  totcount <- c(totcount, as.numeric(fn$sqldf("SELECT COUNT(Year) FROM samplestats WHERE [Finalist Total] == $i")))
}
totfins <- sort(unique(samplestats$`Finalist Total`))
data1plot <- data.frame(totfins, top5count, totcount)
plot1 <- ggplot(data1plot, aes(x=totfins)) + geom_col(aes(y=totcount, fill="Total Finalists"))
plot1 <- plot1 + geom_col(aes(y=top5count, fill="Top 10% of Win Shares")) + ggtitle("Summary of Team's Total Finalists") 
plot1 <- plot1 + geom_text(data=data1plot, aes(y=top5count, label = top5count), vjust=-1)
plot1 <- plot1 + geom_text(data=data1plot, aes(y=totcount, label = totcount), vjust=1)
plot1

data2plot <- data.frame(totfins, samplestats$`Total Win Shares`, samplestats$`True Shooting % Average`, samplestats$`Usage % Average`)
colnames(data2plot) <- c("totfins", "winShares", "avgTS", "avgUSG")
plot2 <- ggplot(data2plot, aes(x=avgTS, y=avgUSG)) + geom_point(aes(size=totfins, color=winShares))
plot2 <- plot2 + ggtitle("Scatterplot of Chosen Statistics, With win shares")
plot2

plot3 <- ggplot(nbadfselected, aes(x=`True Shooting %`, y=`Usage %`)) + geom_point(aes(color=`Win Shares`))
plot3 <- plot3 + ggtitle("Scatterplot of Chosen Statistics from raw data with winshares")
plot3

#---------------------------------------------------------------------------------------------------

testdata1 <- nbadfselected[nbadfselected$MVP == 1, -4:-38]
sqldf("SELECT COUNT(Year) FROM testdata WHERE ([Championship Team] + [Runner Up]) == MVP")

#--------------------------------------------------------------------------------------------------

runnerups <- nbadfselected[nbadfselected$`Runner Up` == 1,]
champs <- nbadfselected[nbadfselected$`Championship Team` == 1,]

runstats <- function(year) {
  print("These tests includes all significant players of each team.")
  fiveR <- runnerups[runnerups$Year == year,]
  fiveC <- champs[champs$Year == year,]
  
  sample1.1 <- fiveR$`True Shooting %`
  sample1.2 <- fiveC$`True Shooting %`

  test1 <- t.test(sample1.1, sample1.2)
  result1 <- test1[[3]] < 0.1
  print(sprintf("This test is for True Shooting %% in year %d", year))
  print(sprintf("The p-value of the test is %f, Reject the null hypothesis: %d", test1[[3]], result1))
  print(sprintf("The means are %f and %f for Runner Up and Champ respectively. The champs were better than the unner ups: %d", test1[[5]][1], test1[[5]][2], test1[[5]][1] < test1[[5]][2]))
  cat("\n")
  sample2.1 <- fiveR$`Usage %`
  sample2.2 <- fiveC$`Usage %`

  test2 <- t.test(sample2.1, sample2.2)
  result2 <- test2[[3]] < 0.1
  print(sprintf("This test is for Usage %% in year %d", year))
  print(sprintf("The p-value of the test is %f, Reject the null hypothesis: %d", test2[[3]], result2))
  print(sprintf("The means are %f and %f for Runner Up and Champ respectively. The champs were better than the unner ups: %d", test2[[5]][1], test2[[5]][2], test2[[5]][1] < test2[[5]][2]))
  cat("\n")
  sample3.1 <- fiveR$`Player Efficiency Rating`
  sample3.2 <- fiveC$`Player Efficiency Rating`

  test3 <- t.test(sample3.1, sample3.2)
  result3 <- test3[[3]] < 0.1
  print(sprintf("This test is for Player Efficiency Rating in %d", year))
  print(sprintf("The p-value of the test is %f, Reject the null hypothesis: %d", test3[[3]], result3))
  print(sprintf("The means are %f and %f for Runner Up and Champ respectively. The champs were better than the unner ups: %d", test3[[5]][1], test3[[5]][2], test3[[5]][1] < test3[[5]][2]))
  cat("\n")

  print("These tests only include the top 5 players of each team.")
  fiveRtop5 <- sqldf("SELECT * FROM fiveR ORDER BY -[Player Efficiency Rating] LIMIT 5")
  fiveCtop5 <- sqldf("SELECT * FROM fiveC ORDER BY -[Player Efficiency Rating] LIMIT 5")

  sample1.1 <- fiveRtop5$`True Shooting %`
  sample1.2 <- fiveCtop5$`True Shooting %`

  test1 <- t.test(sample1.1, sample1.2)
  result1 <- test1[[3]] < 0.1
  print(sprintf("This test is for True Shooting %% in year %d", year))
  print(sprintf("The p-value of the test is %f, Reject the null hypothesis: %d", test1[[3]], result1))
  print(sprintf("The means are %f and %f for Runner Up and Champ respectively. The champs were better than the unner ups: %d", test1[[5]][1], test1[[5]][2], test1[[5]][1] < test1[[5]][2]))
  cat("\n")
  sample2.1 <- fiveRtop5$`Usage %`
  sample2.2 <- fiveCtop5$`Usage %`

  test2 <- t.test(sample2.1, sample2.2)
  result2 <- test2[[3]] < 0.1
  print(sprintf("This test is for Usage %% in year %d", year))
  print(sprintf("The p-value of the test is %f, Reject the null hypothesis: %d", test2[[3]], result2))
  print(sprintf("The means are %f and %f for Runner Up and Champ respectively. The champs were better than the unner ups: %d", test2[[5]][1], test2[[5]][2], test2[[5]][1] < test2[[5]][2]))
  cat("\n")
  sample3.1 <- fiveRtop5$`Player Efficiency Rating`
  sample3.2 <- fiveCtop5$`Player Efficiency Rating`

  test3 <- t.test(sample3.1, sample3.2)
  result3 <- test3[[3]] < 0.1
  print(sprintf("This test is for Player Efficiency Rating in %d", year))
  print(sprintf("The p-value of the test is %f, Reject the null hypothesis: %d", test3[[3]], result3))
  print(sprintf("The means are %f and %f for Runner Up and Champ respectively. The champs were better than the unner ups: %d", test3[[5]][1], test3[[5]][2], test3[[5]][1] < test3[[5]][2]))
  cat("\n")
}

for(i in years) {
  runstats(i)
}

#T-Test Analysis
#In the year 2010, The runner up were statistically better shooters
#In 2007 The top 5 players for the champions were statistically better shooters
#In 2005 The Usage % in 2005 for the top 5 matchup was statistically greater for the champions

#----------------------------------------------

#Average Comparison
#The PER for 2006 all players showed the runner ups having a higher average

#The TS% for 2008 all players showed the runner ups having a higher average
#The PER for 2008 all players showed the runner ups having a higher average
#The TS% for 2008 top 5 showed the runner ups having a higher average
#The PER for 2008 top 5 showed the runner ups having a higher average

#The TS% for 2009 top 5 showed the runner ups having a higher average
#The PER for 2009 top 5 showed the runner ups having a higher average

#The TS% for 2010 all players showed the runner ups having a higher average
#The USG% for 2010 all players showed the runner ups having a higher average
#The TS% for 2010 Top 5 showed the runner ups having a higher average

#The TS% for 2011 all players showed the runner ups having a higher average
#The USG% for 2011 Top 5 showed the runner ups having a higher average
#The PER for 2011 Top 5 showed the runner ups having a higher average

#2012 Top 5 Showed Runner Ups having higher statistics for all 3 measures

#The USG% for 2013 all players showed the runner ups having a higher average

#The TS% for 2014 all players showed the runner ups having a higher average
#2014 Top 5 Showed Runner Ups having higher statistics for all 3 measures

#The TS% for 2015 Top 5 showed the runner ups having a higher average

#------------------------------------------------------------------------------------

samp1 <- sqldf("SELECT Year, [Team], SUM([True Salary]) AS [Team True Salary] FROM nbadfselected WHERE [Runner Up] = 1 GROUP BY Year, Team ORDER BY Year")
samp2 <- sqldf("SELECT Year, [Team], SUM([True Salary]) AS [Team True Salary] FROM nbadfselected WHERE [Championship Team] = 1 GROUP BY Year, Team ORDER BY Year")

mean(samp1$`Team True Salary`)
mean(samp2$`Team True Salary`)

t.test(samp1$`Team True Salary`, samp2$`Team True Salary`)
#------------------------------------------------------------------------------------
# lm model

df <- read.csv(file="nbadata.csv", header=TRUE, sep=",")
head(df)
str(df)

influencesMVPtest <- lm(MVP ~ Player.Efficiency.Rating 
                        + FT.Attempt.Rate 
                        + True.Shooting.. 
                        + Defensive.Win.Shares 
                        + Offensive.Win.Shares 
                        + Usage.. 
                        + Turnover.. 
                        + Box....
                        + Minutes.Played 
                        + Games.Played
                        + Offensive.Box....
                        + Defensive.Box....
                        + X..Shots.of.Team
                        + Team.True.Shooting..
                        + Team.True.Shooting...w.o.Player
                        + True.Salary
                        + Value.over.Replacement.Player
                        + Estimated.Position
                        + Weight
                        + Win.Shares, data = df)
summary(influencesMVPtest)

influencesMVPEdited <- lm(MVP ~ Minutes.Played 
                          + Player.Efficiency.Rating 
                          + FT.Attempt.Rate 
                          + True.Salary
                          + True.Shooting..
                          + Value.over.Replacement.Player, data = df)
summary(influencesMVPEdited)

influencesChampionship <- lm(Championship.Team ~ Team.True.Shooting.. 
                             + Team.Minutes.Played,
                             data = df)
summary(influencesChampionship)
#---------------------------------------------------------------------------------------------
#svm model
library(neuralnet)
EnsurePackage("aod")
projectData <- scale(read.csv(file="nbadata.csv", header=TRUE, sep=",")[,5:42])
str(projectData)
dim(projectData)
str(testData)
projectData[,1:38] <- as.numeric(unlist(projectData[,1:38]))

randIndex <-sample(1:dim(projectData)[1])
cutPoint2_3 <- floor(2* dim(projectData)[1]/3)

trainData <- projectData[randIndex[1:cutPoint2_3],]
testData <- projectData[randIndex[(cutPoint2_3+1):dim(projectData)[1]],]

netoutput <- neuralnet(MVP~Assist..
                  + Win.Shares
                  + X..Shots.of.Team,
                  data=trainData, hidden=4)

summary(netoutput)

netPred <- compute(netoutput, testData[1:37])
compTable <- data.frame(MVP=testData[,38], Prediction=netPred[1,])
table(compTable)

themvps <- nbadfselected[nbadfselected$MVP == 1, 4:38]

avgmvps <- round(sapply(themvps, mean), digits=3)
str(avgmvps)

avgall <- round(sapply(nbadfselected[,4:38], mean), digits=3)

dfmvps <- data.frame(cat=colnames(nbadfselected[,4:38]), avgmvps, avgall, diff=(avgmvps-avgall))
ggplot(dfmvps, aes(x=cat)) + geom_col(aes(y=avgmvps, color="red")) + geom_point(aes(y=avgall, color="black", size="4"))


svmPred
#---------------------------------------------------------------------------------------------
#Viz

TrueSalary <- nbadfselected$`True Salary`
MinutesPlayed <- nbadfselected$`Minutes Played`
plot(MinutesPlayed,TrueSalary)
Model_1<-data.frame(TrueSalary,MinutesPlayed)
mod<- lm(formula= TrueSalary ~ MinutesPlayed, data=Model_1) #Predicts salary based on minutes played
summary(mod)
#47% can be explained therefore, there is a current issue in over paying non-effiecent players. 
abline(mod)

y<-TrueSalary
x<-MinutesPlayed
mean(x)
mean(y)
gplot<- ggplot(Model_1, aes(x=x,y=y)) +geom_point()
gplot
gplot + stat_smooth(method = 'lm', col ='blue')+geom_vline(aes(xintercept=mean(x),color="red"))+geom_hline(yintercept = mean(y), color="red")
#Everything Inside the left of the red intersection is ineffecient spending

PlayerEfec<-nbadfselected$`Player Efficiency Rating`
TrueShooting<-nbadfselected$`True Shooting %`
ThreePtAttRt<-nbadfselected$`3Pt Attempt Rate`
GamesPlayed<-nbadfselected$`Games Played`
FTAttRt<-nbadfselected$`FT Attempt Rate`
YearsExp<-nbadfselected$`Years Experience`

TurnOvers<-nbadfselected$`Turnover %`
mean(TurnOvers)
gplot2<-ggplot(Model_2,aes(x=TurnOvers,y=TrueSalary))+geom_point()
gplot2
gplot2+geom_hline(yintercept = mean(y), color="red")+geom_vline(aes(xintercept=mean(TurnOvers),color="red"))
#Shows everyone inside the left upper quadrant is a defensive liability and overpaid for such.

Model_2<-data.frame(TrueSalary,TurnOvers)
mod2<- lm(formula=TrueSalary~TurnOvers, data=nbadfselected)
summary(mod2)

nbaquick <- nbadfselected[nbadfselected$`Player Efficiency Rating` > 20,]
Years<-nbaquick$Year
PlayerEfec<-nbaquick$`Player Efficiency Rating`
tsal <- nbaquick$`True Salary`
scatterplot3d(tsal,Years,PlayerEfec, pch = 16, highlight.3d=TRUE,
              type="h", main="True Salary v Player Efficiency by The Years")

ChampTeamdf <-data.frame(sqldf("SELECT [Championship Team], Team, Year, SUM([True Salary]) AS [Team True Salary] FROM nbadfselected WHERE [Championship Team] = 1 OR [Runner Up] = 1 GROUP BY Year, [Championship Team] ORDER BY [Year]"))
nonfinalsteam <-data.frame(sqldf("SELECT [Championship Team], Team, Year, SUM([True Salary]) AS [Team True Salary] FROM nbadfselected WHERE [Championship Team] == 0 AND [Runner Up] == 0 GROUP BY Year, Team ORDER BY [Year]"))
TeamSal<-ChampTeamdf$Team.True.Salary
ChampYear<-ChampTeamdf$Year
ChampTeam<-ChampTeamdf$Team
meanch <- sqldf("SELECT AVG([Team.True.Salary]) FROM ChampTeamdf WHERE [Championship.Team] = 1")
meanru <- sqldf("SELECT AVG([Team.True.Salary]) FROM ChampTeamdf WHERE [Championship.Team] = 0")
meanmain <- sqldf("SELECT AVG([Team.True.Salary]) FROM nonfinalsteam")

ChampSalG <- ggplot(ChampTeamdf,aes(x=Year,y=Team.True.Salary,label=Team))+geom_point(aes(color=Championship.Team, size=4))
ChampSalG <- ChampSalG + geom_hline(yintercept = meanch[[1]], size=2, color="red")+geom_text(aes(label=Team),hjust=0,vjust=0)
ChampSalG <- ChampSalG + geom_hline(yintercept = meanru[[1]], size=2, color="black") + scale_color_gradient(low="#000000", high="#FF0000")
ChampSalG + ggtitle("Team Salaries and Averages") + geom_hline(aes(label="avg for all teams"), yintercept = meanmain[[1]], size=2, color="green") + theme(axis.text.y())
##Shows how well each champion team payed in salary that year to win the championship..on average the Spurs paid the most for
#their championships

MVPdf<-sqldf("SELECT [Player Name],[Championship Team], Team, Year, Age,MVP, [Player Efficiency Rating],[Games Played],[Team True Shooting %],[True Salary] FROM nbadfselected WHERE [MVP] = 1 GROUP BY Year ORDER BY [Year]")
#MVPSalG<-ggplot(MVPdf, aes(MVPdf$Year,MVPdf$`True Salary`,label=MVPdf$`Player Name`))
MVPSalG<-ggplot(MVPdf, aes(MVPdf$Year,MVPdf$`True Salary`,label=MVPdf$`Player Name`,color=MVPdf$`Championship Team`)) +geom_bar(stat="identity",color="white")
MVPSalG+geom_text(aes(label=MVPdf$`Player Name`))+coord_flip()+ theme(legend.position="none")
#This graphs the MVPs per year by their salary and indicates if they won the championship or not that year

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


               
