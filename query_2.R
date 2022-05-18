query2sqldf <- sqldf::sqldf("
SELECT Location, COUNT(*) AS Count
FROM (
  SELECT Posts.OwnerUserId, Users.Id, Users.Location
  FROM Users
  JOIN Posts ON Users.Id = Posts.OwnerUserId
)
WHERE Location NOT IN ('')
GROUP BY Location
ORDER BY Count DESC
LIMIT 10
")

mergeddf <- merge.data.frame(Users[,c(1,7)], Posts[,c(1,8)], by.x =1,by.y = 2)

mergeddf <- mergeddf[mergeddf$Location!= '',]
query2base <- aggregate(mergeddf[, c(2)],
                        by = mergeddf[c('Location')],
                        length)
query2base <- query2base[order(-query2base$x),  ]
query2base <- query2base[1:10,]
rownames(query2base) <- 1:10
colnames(query2base)[2] <- c("Count")
query2base


compare::compare(query2base , query2sqldf, allowAll = TRUE)

library(dplyr)
#dplyr
query2dplyr <- Posts %>% 
  select(OwnerUserId) %>%
  left_join( Users[,c("Id","Location")], by = c("OwnerUserId" = "Id")) %>%
  filter(Location != '') %>%
  group_by(Location) %>%
  summarize(Count = n()) %>%
  top_n(10) %>%
  arrange(desc(Count))

compare::compare(query2dplyr , query2sqldf, allowAll = TRUE)

#data.table
query2datatable <- data.table(Id = Users$Id,
                              Location = Users$Location)
query2datatable <- query2datatable[ data.table(OwnerUserId = Posts$OwnerUserId), on = .(Id = OwnerUserId)]
query2datatable <- query2datatable[Location != '',.(Count = .N), by = Location][with(query2datatable,order(-Count)),][1:10,]

compare::compare(query2datatable , query2sqldf, allowAll = TRUE)
