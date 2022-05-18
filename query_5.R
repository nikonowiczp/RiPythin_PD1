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
VotesByAge2 <- aggregate.data.frame(VotesByAge[,c('Total', 'VoteDate')],
                         by = VotesByAge[c('PostId')],
                         function (x) c( Votes = sum(x,na.rm = TRUE,
                                                           print(x))
                         ))


head(VotesByAge2)
colnames(VotesByAge2)[2] = 'Votes'
VotesByAge2$NewVotes <- 
VotesByAge2$OldVotes <- lapply (VotesByAge2$PostId, function(x){ max(VotesByAge[VotesByAge$PostId == x & VoteDate == "old",c('Total')])} )


head(Votes)




#dplyr
query5dplyr <- Votes %>%
  filter(VoteTypeId %in% c(1,2,5)) %>%
  mutate(VoteDate = ifelse(substr(as.character(CreationDate),1,4) %in% c('2021', '2020'), "new", "old") ) %>%
  group_by(PostId, VoteDate) %>%
  summarize(Total = n()) %>%
  group_by(PostId) %>%
  summarize(NewVotes = max(ifelse(VoteDate=="new", Total, 0)), OldVotes= max(ifelse(VoteDate=="old", Total, 0)), Votes = sum(Total)) %>%
  filter(NewVotes == 0) %>%
  #We have VotesByAge2
  right_join(Posts[,c("Title","PostTypeId","Id")], by = c("PostId" = "Id")) %>%
  filter(PostTypeId == 1) %>%
  select(Title = Title, OldVotes = OldVotes) %>%
  top_n(OldVotes, n = 10) %>%
  arrange(desc(OldVotes)) %>%
  slice(1:10)

compare::compare(query5dplyr , query5sqldf, allowAll = TRUE)




#data.table
query5datatable <- data.table(PostId = Votes$PostId,
                              CreationDate = Votes$CreationDate, 
                              VoteTypeId = Votes$VoteTypeId)
query5datatable <- query5datatable[VoteTypeId %in% c(1,2,5) , .(PostId = PostId , VoteDate = ifelse(substr(as.character(CreationDate),1,4) %in% c('2021', '2020'), "new", "old"))]
query5datatable <- query5datatable[, .(Total = .N), by = list(PostId, VoteDate)]
query5datatable <- query5datatable[, .(NewVotes = max(ifelse(VoteDate=="new", Total, as.integer(0))), OldVotes = max(ifelse(VoteDate=="old", Total,as.integer(0))  ), Votes = sum(Total)), by = PostId]
query5datatable <- query5datatable[NewVotes == 0,]
query5datatable <- query5datatable[data.table(Id = Posts$Id, Title = Posts$Title, PostTypeId = Posts$PostTypeId), on = .(PostId = Id), nomatch = NULL]
query5datatable <- query5datatable[PostTypeId == 1, .(Title = Title, OldVotes = OldVotes)]
query5datatable <- query5datatable[with(query3datatable,order(-OldVotes)),][1:10,]

compare::compare(query5datatable , query5sqldf, allowAll = TRUE)
