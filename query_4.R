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
