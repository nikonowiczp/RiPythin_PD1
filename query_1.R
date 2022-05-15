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