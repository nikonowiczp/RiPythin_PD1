query3sqldf <- sqldf::sqldf('
SELECT
  Users.AccountId,
  Users.DisplayName,
  Users.Location,
  AVG(PostAuth.AnswersCount) as AverageAnswersCount
FROM
(
  SELECT
    AnsCount.AnswersCount,
    Posts.Id,
    Posts.OwnerUserId
  FROM (
        SELECT Posts.ParentId, COUNT(*) AS AnswersCount
        FROM Posts
        WHERE Posts.PostTypeId = 2
        GROUP BY Posts.ParentId
        ) AS AnsCount
  JOIN Posts ON Posts.Id = AnsCount.ParentId
  ) AS PostAuth
JOIN Users ON Users.AccountId=PostAuth.OwnerUserId
GROUP BY OwnerUserId
ORDER BY AverageAnswersCount DESC
LIMIT 10
')

            

AnsCount <-Posts[Posts$PostTypeId == 2,c('ParentId'),drop = FALSE]
AnsCount <- aggregate(AnsCount[, c(1)],
                        by = AnsCount[c('ParentId')],
                        length)
colnames(AnsCount)[2] <- 'AnswersCount'
mergedData <- merge.data.frame(AnsCount, Posts[,c('Id','OwnerUserId')], by.x =1, by.y = 1)
mergedData <- merge.data.frame(mergedData, Users[,c('AccountId','DisplayName','Location')], by.x =3, by.y = 1)
query3base <- aggregate(mergedData[, c('AnswersCount')],
                        by = mergedData[c('OwnerUserId')],
                        mean)
colnames(query3base)[2] <- 'AverageAnswersCount'
query3base <- merge.data.frame(mergedData,query3base,by.x =1, by.y = 1)
query3base <- query3base[order(-query3base$AverageAnswersCount),  ]
query3base <- query3base[1:10,]
query3base <- data.frame(
  AccountId = query3base$OwnerUserId,
  DisplayName = query3base$DisplayName,
  Location = query3base$Location,
  AverageAnswersCount = query3base$AverageAnswersCount
)
compare::compare(query3base , query3sqldf, allowAll = TRUE)

#dplyr
query3dplyr <- Posts %>%
  filter(PostTypeId == 2) %>%
  select(ParentId) %>% 
  group_by(ParentId) %>%
  summarize(AnswersCount = n()) %>%
  left_join(Posts[,c("Id", "OwnerUserId")], by = c("ParentId" = "Id")) %>%
  rename(Id= ParentId) %>%
  #here we have full post auth
  group_by(OwnerUserId) %>%
  summarize(AverageAnswersCount = mean(AnswersCount)) %>%
  right_join(Users[,c("AccountId", "DisplayName", "Location")], by = c("OwnerUserId" = "AccountId")) %>%
  rename(AccountId = OwnerUserId) %>%
  top_n(AverageAnswersCount, n = 10) %>%
  relocate(AverageAnswersCount, .after = Location) %>%
  arrange(desc(AverageAnswersCount),AccountId)

compare::compare(query3dplyr , query3sqldf, allowAll = TRUE)


#data.table
query3datatable <- data.table(ParentId = Posts$ParentId,
                             PostTypeId = Posts$PostTypeId)
query3datatable <- query3datatable[PostTypeId == 2,.(AnswersCount = .N) ,by = ParentId]
query3datatable <- query3datatable[data.table(Id = Posts$Id, OwnerUserId = Posts$OwnerUserId), on = .(ParentId = Id),nomatch = NULL]
query3datatable <- query3datatable[data.table(AccountId = Users$AccountId, DisplayName = Users$DisplayName, Location = Users$Location), on = .(OwnerUserId=AccountId), nomatch = NULL]
query3datatable <- query3datatable[, .(DisplayName = DisplayName, Location = Location, AverageAnswersCount = mean(AnswersCount)) , by = OwnerUserId]
query3datatable <- query3datatable[with(query3datatable,order(-AverageAnswersCount)),][1:10,]
setnames(query3datatable, "OwnerUserId", "AccountId")

compare::compare(query3datatable , query3sqldf, allowAll = TRUE)


