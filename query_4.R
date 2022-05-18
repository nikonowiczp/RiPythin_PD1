query4sqldf <- sqldf::sqldf("
SELECT
  Posts.Title,
  UpVotesPerYear.Year,
  MAX(UpVotesPerYear.Count) AS Count
FROM (
      SELECT
        PostId,
        COUNT(*) AS Count,
        STRFTIME('%Y', Votes.CreationDate) AS Year
      FROM Votes
      WHERE VoteTypeId=2
      GROUP BY PostId, Year
      ) AS UpVotesPerYear
JOIN Posts ON Posts.Id=UpVotesPerYear.PostId
WHERE Posts.PostTypeId=1
GROUP BY Year
ORDER BY Year ASC
")

YearData <- data.frame(
  PostId = Votes[Votes$VoteTypeId==2,c('PostId')],
  Year = substr(as.character(Votes[Votes$VoteTypeId==2,c('CreationDate')]), 1, 4)
)
UpVotesPerYear <- aggregate(YearData[, c('PostId')],
                            by = YearData[c('PostId','Year')],
                            length)
colnames(UpVotesPerYear)[3] <- 'Count'

query4base <- merge.data.frame(Posts[Posts$PostTypeId == 1,c('Id','Title')], UpVotesPerYear, by.x = 1, by.y = 1)
counts <- aggregate(query4base[, c('Count')],
                            by = query4base[c('Year')],
                            max )
colnames(counts)[2]='Count'
query4base <- merge.data.frame(counts,query4base[,c('Title','Year', 'Count')], by =c('Year', 'Count'))
query4base <- query4base[,c(3,1,2)]

compare::compare(query4base , query4sqldf, allowAll = TRUE)




#dplyr
query4dplyr <- Votes %>%
  filter(VoteTypeId == 2) %>%
  mutate(Year =  substr(CreationDate,1,4)) %>%
  select(PostId, Year) %>%
  group_by(PostId, Year) %>%
  summarize(Count = n()) %>%
  #UpvotesPerYear
  left_join(Posts[,c("Id","Title","PostTypeId")], by = c("PostId" = "Id")) %>%
  filter(PostTypeId == 1) %>%
  group_by(Year) %>%
  filter(Count == max(Count)) %>%
  select(Title = Title, Year = Year, Count = Count) %>%
  arrange(Year)


compare::compare(query4dplyr , query4sqldf, allowAll = TRUE)

head(query4sqldf)


#data.table
library(data.table)
query4datatable <- data.table(PostId = Votes$PostId, CreationDate = Votes$CreationDate, VotesTypeId = Votes$VoteTypeId)
query4datatable <- query4datatable[,Year := substr(CreationDate,1,4)]
query4datatable <- query4datatable[VotesTypeId == 2, .(Count = .N), by = list(PostId, Year)]
query4datatable <- query4datatable[data.table(Id = Posts$Id, Title = Posts$Title, PostTypeId = Posts$PostTypeId), on = .(PostId = Id), nomatch = NULL]
query4datatable <- query4datatable[PostTypeId == 1, .SD[which.max(Count)], by = Year]
query4datatable <- query4datatable[,.(Title = Title, Year = Year, Count = Count)][with(query3datatable,order(Year)),]

compare::compare(query4datatable , query4sqldf, allowAll = TRUE)
