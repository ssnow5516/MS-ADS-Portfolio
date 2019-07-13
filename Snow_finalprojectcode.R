## Scott Snow
## Final Project Code
## IST 719
## June 6, 2019

## Focus of data collection is to get daily set of twitch.tv stream data and explore visually.
## Then get viewer counts and prize pool for specific tournaments and leagues. 
library(httr)
library(jsonlite)
library(lubridate)
library(dplyr)


client_id <- "nniyigv0onb6h5d1cif8c0k8zfnehy"

client_secret <- "fd2u5fk63pyng55vo192yjrwwjnplz"


#-----------------------------------------------------------------------
## from https://curl.trillworks.com/#r
## rawToChar from https://stat.ethz.ch/R-manual/R-devel/library/base/html/rawConversion.html

headers = c(
  `Client-ID` = client_id
)
## Sys.sleep(60) due to rate limiting
## from https://www.alexejgossmann.com/benchmarking_r/
getGameID <- function(id) {
  gamesurl <- "https://api.twitch.tv/helix/games"
  params = list(`id` = id)
  games <- GET(url = gamesurl, add_headers(.headers=headers), query = params)
  if(games$status_code == 429){
    Sys.sleep(60)
    games <- GET(url = gamesurl, add_headers(.headers=headers), query = params)
  }
  jsoncont2 <- rawToChar(games$content, multiple=FALSE)
  json2 <- fromJSON(jsoncont2)
  return(json2$data$name)
}

getCurrDur <- function(DateTime2) {
  dt2 <- as.POSIXct(DateTime2,format="%Y-%m-%dT%H:%M:%SZ",tz="UTC")
  current <- Sys.time()
  attr(current, "tzone") <- "UTC"
  return(as.double(current-dt2))
}

getUserInfo <- function(user_id) {
  params = list(`id` = user_id)
  user <- GET(url = "https://api.twitch.tv/helix/users", add_headers(.headers=headers), query = params)
  if(user$status_code == 429){
    Sys.sleep(60)
    user <- GET(url = "https://api.twitch.tv/helix/users", add_headers(.headers=headers), query = params)
  }
  jsoncont3 <- rawToChar(user$content, multiple=FALSE)
  json3 <- fromJSON(jsoncont3)
  return(c(json3$data$broadcaster_type, json3$data$view_count))
}
## for project, 
## its likely that most streamers maintain a relative position
## Still trying to reduce variation as much as possible
## using 500 rows
rowgoals <- 500
pagegoals <- rowgoals/100

finaldf <- data.frame(factor(), factor(), integer(), double(), factor(), integer())
colnames(finaldf) <- c("Name", "Game", "Current Views", "Current Duration", "Broadcaster Type", "Total Views")

nxtcrsr <- ""
for (x in 1:pagegoals) {
  params = list(
    `first` = '100'
    ,`after` = nxtcrsr 
  )

  res <- httr::GET(url = 'https://api.twitch.tv/helix/streams', httr::add_headers(.headers=headers), query = params)
  if(res$status_code == 429){
    Sys.sleep(60)
    res <- httr::GET(url = 'https://api.twitch.tv/helix/streams', httr::add_headers(.headers=headers), query = params)
  }
  jsoncont <- rawToChar(res$content, multiple=FALSE)
  json <- fromJSON(jsoncont)

  #json$data$user_name
  #class(json$data$started_at)
  ## from https://stackoverflow.com/questions/25960517/how-to-convert-date-and-time-from-character-to-datetime-type
  ## from the json's date time, returns the streams current duration

  userbtypes <- c()
  channelviews <- c()
  for (x in json$data$user_id) {
    userinfo <- getUserInfo(x)
    userbtypes <- c(userbtypes, userinfo[1])
    channelviews <- c(channelviews, userinfo[2])
  }
  use_len <- min(length(json$data$user_id),length(userbtypes))
  gamelist <- lapply(json$data$game_id, getGameID)
  thisdf <- data.frame(json$data$user_name[1:use_len],as.character(gamelist)[1:use_len],json$data$viewer_count[1:use_len]
                      ,as.double(lapply(json$data$started_at, getCurrDur))[1:use_len], userbtypes, as.integer(channelviews))

  colnames(thisdf) <- c("Name", "Game", "Current Views", "Current Duration", "Broadcaster Type", "Total Views")
  finaldf <- rbind(finaldf, thisdf)

  nxtcrsr <- json$pagination$cursor
}

str(finaldf)


finaldf$`Broadcaster Type` <- factor(finaldf$`Broadcaster Type`, levels=c("","streamer", "partner", "affiliate"))
finaldf$`Broadcaster Type`[finaldf$`Broadcaster Type`==""] <- "streamer"
finaldf$`Broadcaster Type` <- factor(finaldf$`Broadcaster Type`, levels=c("streamer", "partner", "affiliate"))

curr_date <- Sys.Date()

write.csv(finaldf, paste(curr_date,"_data.csv"))

## excluded visualization code in hw4.

#----------------------------------------------------------------------------------------------
use_path <- "E:/Documents/School2019/SU_ADS_April_2019_Term/IST719/code/proj_Data/twitchapidata"
setwd(use_path)
file.names <- dir(use_path, pattern =".csv")
twitch_df <- read.csv(file.names[1])
twitch_df$date <- date(substr(file.names[1],1,10))
str(twitch_df)
for(i in 2:length(file.names)){
  this_df <- read.csv(file.names[i])
  this_df$date <- date(substr(file.names[i],1,10))
  twitch_df <- rbind(twitch_df,this_df)
}
str(twitch_df)
#----------------------------------------------------------------------------------------------
library(ggplot2)
## average view duration per game = sum current views / 
colnames(twitch_df)[2] <- 'tag'
inner1 <- sqldf("SELECT tag,Game,MAX(`Total.Views`) AS m_views, SUM(`Current.Duration`) as TotalHours FROM twitch_df GROUP BY tag")
games_viewers_df <- sqldf("SELECT Game, SUM(m_views) AS ViewsPerGame, SUM(TotalHours) AS TotalHours FROM inner1 GROUP BY Game")
games_viewers_df$ViewsPerGame <- as.double(games_viewers_df$ViewsPerGame)
games_viewers_df <- arrange(games_viewers_df,-ViewsPerGame)
notgames <- c("Talk Shows & Podcasts", "Just Chatting", 'NULL')
games_viewers_df <- games_viewers_df[!(games_viewers_df$Game %in% notgames),]
games_viewers_df <- na.omit(games_viewers_df)
str(games_viewers_df)

## check games plot with top 500 streamers by sum current.views. then do back to back plot.  


gms_vws_plt <- ggplot(games_viewers_df[1:20,], aes(x=reorder(Game,ViewsPerGame), y=ViewsPerGame)) + geom_bar(stat = 'identity',aes(fill=TotalHours))
gms_vws_plt <- gms_vws_plt + coord_flip() + scale_y_continuous(labels=scales::comma) + ylab("Channel Views Per Game") + xlab("Game")
gms_vws_plt + ggtitle("Most Viewed Games") + scale_fill_continuous(low="#BA3300", high="#FFC745")

games_viewers_df2 <- sqldf("SELECT Game, COUNT(Game) AS StreamersPerGame, AVG(`Current.Views`) AS ViewsPerGame FROM twitch_df GROUP BY Game")
games_viewers_df2 <- arrange(games_viewers_df2,-StreamersPerGame)
games_viewers_df2 <- games_viewers_df2[!(games_viewers_df2$Game %in% notgames),]
games_viewers_df2 <- na.omit(games_viewers_df2)

inner3 <- intersect(games_viewers_df2$Game[1:100],topgames2$game[1:100])

gms_vws_plt2 <- ggplot(games_viewers_df2[games_viewers_df2$Game %in% inner3,], aes(x=Game, y=StreamersPerGame)) + geom_bar(stat = 'identity',aes(fill=ViewsPerGame))
gms_vws_plt2 <- gms_vws_plt2 + coord_flip() + scale_y_continuous(labels=scales::comma) + ylab("Number of Streamers") + xlab("Game")
gms_vws_plt2 + ggtitle("GAME POPULARITY: STREAMERS") + scale_fill_continuous(low="#BA3300", high="#FFC745")


#----------------------------------------------------------------------------------------------

## import top100 games

topgames <- read.csv('proj_Data/top100games.tsv', sep='\t')
str(topgames)


## from http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html#Treemap
#install.packages("treemapify")
library(treemapify)


## PLot is tree map subgrouped by genre, area by total_plyrs in a game, fill is total prizes
gms_plot <- ggplot(topgames, aes(area=total_plyrs, fill=total_prizes, label=game, subgroup=genre)) + geom_treemap()
gms_plot <- gms_plot + geom_treemap_subgroup_text(place = "centre", grow = T, alpha = 0.5, colour="#FFFFD6", fontface = "bold", min.size = 0) +
  geom_treemap_text(colour = "white", place = "topleft", reflow = T) +
  geom_treemap_subgroup_border(colour = "white", size = 0) + scale_fill_continuous(low="#2A8E60", high="#BAE347", labels=scales::comma)
gms_plot + ggtitle("Players Per Game")

topgames2 <- arrange(topgames, -total_plyrs)

gms_plot2 <- ggplot(topgames2[topgames2$game %in% inner3,], aes(x=game, y=total_plyrs, fill=total_prizes, subgroup=genre)) + geom_bar(stat = 'identity')
gms_plot2 <- gms_plot2 + scale_fill_continuous(low="#2A8E60", high="#BAE347", labels=scales::comma)
gms_plot2 <- gms_plot2 + scale_x_discrete(position = "top") + scale_y_reverse() + coord_flip() + theme(legend.position = "left")
gms_plot2 + ggtitle("GAME POPULARITY: PLAYERS IN COMPETITION")

#----------------------------------------------------------------------------------------------

use_path <- "E:/Documents/School2019/SU_ADS_April_2019_Term/IST719/code/"
setwd(use_path)
## import player earnings
top500plyrs <- read.csv('proj_Data/top500plyrs.tsv', sep='\t')
str(top500plyrs)
str(twitch_df)
## streamers who are top 500 earners


plyrs_w_strms <- intersect(top500plyrs$tag, twitch_df$tag)

top_streamers_df <- twitch_df[twitch_df$tag %in% plyrs_w_strms,]
top_streamers_df$tag <- as.character(top_streamers_df$tag)
str(top_streamers_df)

stream_time_plt <- ggplot(top_streamers_df[top_streamers_df$Current.Views>500,], aes(x=date,y=Current.Views)) + geom_line(aes(color=tag))
stream_time_plt <- stream_time_plt + geom_point(aes(color=tag, size=Current.Duration, shape=Broadcaster.Type)) + ggtitle("Stream Viewership June 6th - June 16th")
stream_time_plt



earnings_viewers <- inner_join(top500plyrs, twitch_df, by='tag')
str(earnings_viewers)

library(sqldf)

earnings_viewers <- sqldf("SELECT tag, total_earn AS earnings, SUM(`Current.Duration`) AS ttl_duration, `Total.Views` AS viewers FROM earnings_viewers GROUP BY tag")

plyrs_plot <- ggplot(earnings_viewers, aes(x=ttl_duration, y=tag, size=earnings, color=viewers)) + geom_point()
plyrs_plot <- plyrs_plot + scale_color_continuous(low="#BA3300", high="#FFC745", labels=scales::comma) + ggtitle("Streamers in the top 500 Earners")
plyrs_plot + scale_size_continuous(range = c(10,30)) + theme_minimal()



#-----------------------------------------------------------------------------------------------
## import indv_tourns
indv_tourns <- read.csv('proj_Data/top500indv_tourns.tsv', sep='\t')
colnames(indv_tourns)[3:4] <- c('prize_pool','game')
str(indv_tourns)

## import team_tounrs
team_tourns <- read.csv('proj_Data/top500team_tourns.tsv', sep='\t')
str(team_tourns)

#----------------------------------------------------------------------------------------------
indv_tourns$Gametype <- 'individual'
team_tourns$Gametype <- 'team'
all_tourns <- rbind(indv_tourns, team_tourns[,-5])
all_tourns$przpplyrs <- all_tourns$prize_pool/all_tourns$num_plyrs
str(all_tourns)
bigmoney <- all_tourns[all_tourns$prize_pool>4000000,]
manyplyr <- all_tourns[all_tourns$num_plyrs>150,]
all_tourns <- all_tourns[all_tourns$prize_pool<4000000,]
all_tourns <- all_tourns[all_tourns$num_plyrs<150,]

library(gridExtra)

p1 <- ggplot(all_tourns, aes(x=num_plyrs, y=prize_pool)) + geom_hex() + ggtitle('Players versus Prize Pool') +
  theme(legend.position = c(0.9,0.9)) + scale_y_continuous(labels=scales::comma)
p2 <- ggplot(bigmoney, aes(x=num_plyrs, y=prize_pool, color=Gametype, label=title)) + geom_point(size=4) +
  theme(legend.position = 'none') + scale_y_continuous(labels=scales::comma) + geom_text(aes(label=title),hjust=1.2, vjust=1)
p3 <- ggplot(manyplyr, aes(x=num_plyrs, y=prize_pool, color=Gametype, label=title)) + geom_point(size=4) +
  theme(legend.position = 'none') + scale_y_continuous(labels=scales::comma) + geom_text(aes(label=title),hjust=1.2, vjust=1)
p1 + scale_fill_continuous(low="#BA3300", high="#BAE347")
p2 + scale_x_reverse() + coord_flip()
p3










