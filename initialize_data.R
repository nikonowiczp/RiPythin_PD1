setwd("C:/Users/patry/Documents/Projekty/Semestr_6/R i Python/PD/PD1/Nikonowicz_Patryk_305918_pd1")

if ( options()$stringsAsFactors )
  options(stringsAsFactors=FALSE) # dla R w wersji < 4.0
# ww. pliki znajduj¹ siê w katalogu travel_stackexchange_com
Badges <- read.csv("travel_stackexchange_com/Badges.csv.gz")
head(Badges)

Comments <- read.csv("travel_stackexchange_com/Comments.csv.gz")
head(Comments)

PostLinks <- read.csv("travel_stackexchange_com/PostLinks.csv.gz")
head(PostLinks)

Posts <- read.csv("travel_stackexchange_com/Posts.csv.gz")
head(Posts)

Tags <- read.csv("travel_stackexchange_com/Tags.csv.gz")
head(Tags)

Users <- read.csv("travel_stackexchange_com/Users.csv.gz")
head(Users)

Votes <- read.csv("travel_stackexchange_com/Votes.csv.gz")
head(Votes)

