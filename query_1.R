query1sqldf <- sqldf::sqldf('
SELECT
      Name,
      COUNT(*) AS Number,
      MIN(Class) AS BestClass
      FROM Badges
      GROUP BY Name
      ORDER BY Number DESC
      LIMIT 10
')

#using built in functions
query1base <- aggregate(Badges[, c(5)],
          by = Badges[c('Name')],
          function(x) c(Number = length(x),
                        BestClass = min(x, na.rm = TRUE) ))
query1base <- cbind.data.frame(Name = query1base[, 1], query1base[, 2])
query1base <- query1base[order(-query1base$Number),  ]
query1base <- query1base[1:10,]
rownames(query1base) <- 1:nrow(query1base)
query1base



compare::compare(query1base , query1sqldf, allowAll = TRUE)


#dplyr

query1dplyr <- Badges %>% 
  group_by(Name) %>%
  summarize(Number = n(), BestClass = min(Class)) %>%
  top_n(Number,n = 10) %>%
  arrange(desc(Number))

compare::compare(query1dplyr , query1sqldf, allowAll = TRUE)


#data.table

query1datatable <- data.table(Name = Badges$Name, 
                              Class = Badges$Class)
query1datatable <- query1datatable[ ,.( Number =.N, BestClass = min(Class)), by = .(Name)][with(query1datatable,order(-Number)),][1:10,]

compare::compare(query1datatable , query1sqldf, allowAll = TRUE)
