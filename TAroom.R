## Extract rooms
rooms <- read.csv("MPH TA office hours.csv", stringsAsFactors = FALSE, na.strings = "")
rooms <- rooms[complete.cases(rooms), ]
rooms$date <- as.Date(rooms$Date, format = "%m/%d/%y")
rooms <- rooms[order(rooms$date), ]
rooms$dateChar <- as.character(rooms$date)

tas <- c("Leo", "Youssef", "Danielle", "Emily")
TAroom <- lapply(tas, function(ta) {
    use <- rooms[grepl(ta, rooms$TA), ]
    res <- use$Room
    names(res) <- use$dateChar
    return(res)
})
names(TAroom) <- tas
save(TAroom, file = "TAroom.Rdata")
