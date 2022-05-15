query5sqldf <- sqldf::sqldf("
SELECT
  Posts.Title,
  VotesByAge2.OldVotes
FROM Posts
JOIN (
      SELECT
      PostId,
      MAX(CASE WHEN VoteDate = 'new' THEN Total ELSE 0 END) NewVotes,
      MAX(CASE WHEN VoteDate = 'old' THEN Total ELSE 0 END) OldVotes,
      SUM(Total) AS Votes
      FROM (
        SELECT
          PostId,
          CASE STRFTIME('%Y', CreationDate)
          WHEN '2021' THEN 'new'
          WHEN '2020' THEN 'new'
          ELSE 'old'
          END VoteDate,
          COUNT(*) AS Total
        FROM Votes
        WHERE VoteTypeId IN (1, 2, 5)
        GROUP BY PostId, VoteDate
      ) AS VotesByAge
      GROUP BY VotesByAge.PostId
      HAVING NewVotes=0
) AS VotesByAge2 ON VotesByAge2.PostId=Posts.ID
WHERE Posts.PostTypeId=1
ORDER BY VotesByAge2.OldVotes DESC
LIMIT 10
")

VotesByAge <- data.frame(
  PostId = Votes[Votes$VoteTypeId %in% c(1,2,5),c('PostId')],
  VoteDate = ifelse( substr(as.character(Votes[Votes$VoteTypeId %in% c(1,2,5),c('CreationDate')]), 1, 4) %in% c('2021', '2020'),  "new" , "old")
)
VotesByAge <- aggregate(VotesByAge[, c('VoteDate')],
                        by = VotesByAge[c('VoteDate','PostId')],
                        length)
colnames(VotesByAge)[3] <- 'Total'
VotesByAge2 <- aggregate(VotesByAge[,c('Total')],
                         by = VotesByAge[c('PostId')],
                         function (x) c(Votes = sum(x,na.rm = TRUE),
                                        length()
                         ))
head(VotesByAge2)
a <- print(c(1,2))