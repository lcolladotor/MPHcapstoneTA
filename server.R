## Setup
library("shiny")
#library("sendmailR")
library("mail")
library("rdrop2")

## Load data
load("tapass.Rdata")
load("taemails.Rdata")
load("TAroom.Rdata")
token <- readRDS("lcollado-droptoken.rds")

## Options
TAchoices <- list(
	"Monday" = c("Choose a TA", "Emily Hurley" = "Emily"),
	"Tuesday" = c("Choose a TA", "Danielle Edwards" = "Danielle", "Emily Hurley" = "Emily", "Leonardo Collado Torres" = "Leo"),
	"Wednesday" = c("Choose a TA"),
	"Thursday" = c("Choose a TA", "Danielle Edwards" = "Danielle", "Youssef Farag" = "Youssef"),
	"Friday" = c("Choose a TA", "Youssef Farag" = "Youssef", "Leonardo Collado Torres" = "Leo")
)

TAhour <- list(
	"Youssef" = list(
		"Monday" = "00:00",
		"Tuesday" = "00:00",
		"Wednesday" = "00:00",
		"Thursday" = c("13:15-13:45", "13:45-14:15", "14:15-14:45", "14:45-15:15"),
		"Friday" = c("14:00-14:30", "14:30-15:00", "15:00-15:30", "15:30-16:00", "16:00-16:30", "16:30-17:00", "17:00-17:30", "17:30-18:00")
	),
	"Leo" = list(
		"Monday" = "00:00",
		"Tuesday" = c("13:00-13:30", "13:30-14:00", "14:00-14:30", "14:30-15:00"),
		"Wednesday" = "00:00",
		"Thursday" = "00:00",
		"Friday" = c("13:00-13:30", "13:30-14:00", "14:00-14:30", "14:30-15:00")
	),
	"Danielle" = list(
		"Monday" = "00:00",
		"Tuesday" = c("10:30-11:00", "11:00-11:30", "11:30-12:00", "12:00-12:30"),
		"Wednesday" = "00:00",
		"Thursday" = c("10:30-11:00", "11:00-11:30", "11:30-12:00", "12:00-12:30"),
		"Friday" = "00:00"
	),
	"Emily" = list(
		"Monday" = c("14:30-15:00", "15:00:15-30", "15:30-16:00", "16:00-16:30"),
		"Tuesday" = c("09:00-09:30", "09:30-10:00", "10:00-10:30", "10:30-11:00"),
		"Wednesday" = "00:00",
		"Thursday" = "00:00",
		"Friday" = "00:00"
	),
	"Choose a TA" = list("Monday" = "00:00", "Tuesday" = "00:00", "Wednesday" = "00:00", "Thursday" = "00:00", "Friday" = "00:00")
)

## Download latest from Dropbox
drop_get("github/MPHcapstoneTA/reservations.Rdata", overwrite = TRUE, dtoken = token)
drop_get("github/mphcapstoneta/www/publicCalendar.ics", local_file = "www/publicCalendar.ics", overwrite = TRUE, dtoken = token)
drop_get("github/mphcapstoneta/www/publicCalendar-Leo.ics", local_file = "www/publicCalendar-Leo.ics", overwrite = TRUE, dtoken = token)
drop_get("github/mphcapstoneta/www/publicCalendar-Emily.ics", local_file = "www/publicCalendar-Emily.ics", overwrite = TRUE, dtoken = token)
drop_get("github/mphcapstoneta/www/publicCalendar-Youssef.ics", local_file = "www/publicCalendar-Youssef.ics", overwrite = TRUE, dtoken = token)
drop_get("github/mphcapstoneta/www/publicCalendar-Danielle.ics", local_file = "www/publicCalendar-Danielle.ics", overwrite = TRUE, dtoken = token)

## Save reservations
saveRes <- function(reservations, file = 'reservations.Rdata', dest = "github/MPHcapstoneTA") {
    save(reservations, file = file)
    drop_upload(file, dest = dest, dtoken = token)
}

reservationsHist <- drop_history('github/mphcapstoneta/reservations.rdata', dtoken = token)
save(reservationsHist, file = 'reservationsHist.Rdata')

## Assign room
assignRoom <- function(TA, desiredDate) {
    
    if(TA %in% names(TAroom)) {
        possibleRooms <- TAroom[[TA]]
        charDate <- as.character(as.Date(desiredDate, tz="America/New_York"))
        if(charDate %in% names(possibleRooms)) {
            mtgRoom <- possibleRooms[[charDate]]
        } else {
            mtgRoom <- "*to be determined*"
        }
    } else {
        mtgRoom <- "*to be determined*"
    }
	
	## Done
	return(mtgRoom)
}

## Select the date for the reservation
getDesiredDate <- function(data) {
	possible <- which(data$Weekday == weekdays(data$minimumPossible + 0:7 * 24 * 60^2))

	## Find the day which works
	if(length(possible) == 2) {
		tmp <- as.POSIXlt(data$minimumPossible)
		wantedHour <- as.integer(substr(data$officeHour, 1, 2))
		if(wantedHour > tmp$hour) {
			possible <- possible[1]
		} else if(wantedHour == tmp$hour & as.integer(substr(data$officeHour, 4, 5)) >= tmp$min) {
			possible <- possible[1]
		} else {
			possible <- possible[2]
		}
	}

	## Construct the desired date
	res <- as.POSIXlt(paste(as.Date(data$minimumPossible, tz="America/New_York") + possible - 1, substr(data$officeHour, 1, 5)), "America/New_York")
	return(res)
}

## Build message
buildMsg <- function(new, tentative="*tentative* ") {
	tmpSkype <- paste0(c(" (skype ID: ", new$Skype, ")"), collapse="")
	
	## Assign room
	mtgRoom <- assignRoom(new$TA, new$desiredDate)
		
	## Construct the message
	msg <- paste0(c(
		"Dear ", new$Student, ", your ", tentative, "office hour reservation is with TA ", new$TA, " on ", as.character(as.Date(new$desiredDate, tz="America/New_York")), " at ", new$officeHour, ". You have specified that your email is ", new$Email, ". Furthermore, you are ", ifelse(new$Distance == "No", "not ", ""), "a distance student", ifelse(new$Distance == "Yes", tmpSkype, ""), ", and your MPH concentration is '", new$Concentration, "'.\n The meeting will be at ", mtgRoom, "."
	), collapse="") 
	return(msg)
}

## Check that the entry is valid
checkEntry <- function(new, reservations, verbose=TRUE) {
	res <- "Incomplete"
	if(new$TA == "Choose a TA") {
		if(verbose) cat("Guide: Please choose a TA\n")
	} else if(new$Student == "Your name") {
		if(verbose) cat("Guide: Please enter your name.\n")
	} else if (new$Email == "Your email") {
		if(verbose) cat("Guide: Please enter your email.\n")
	} else if (!grepl('@', new$Email)) {
        if(verbose) cat("Guide: Please enter a valid email address")
    } else if (new$officeHour == "00:00"){
		if(verbose) cat("Guide: Please choose a valid office hour.\n")
	} else if (new$Distance == "Yes" & new$Skype == "") {
		if(verbose) cat("Guide: Please provide us your Skype username.\n")
	} else if (new$Concentration == "Choose your concentration") {
		if(verbose) cat("Guide: Please choose your MPH concentration.\n")
	} else {
		## Does the reservation already exist? Cancelling?
		pre <- subset(reservations, TA == new$TA & tolower(Student) == tolower(new$Student) & tolower(Email) == tolower(new$Email) & Distance == new$Distance & tolower(Skype) == tolower(new$Skype) & Concentration == new$Concentration & desiredDate == new$desiredDate)
				
		## Is there an overlap? Someone reserved the slot already?
		ov <- subset(reservations, TA == new$TA & desiredDate == new$desiredDate)
		
		## Do you already have a reservation?
		gotone <- subset(reservations, tolower(Student) == tolower(new$Student) & tolower(Email) == tolower(new$Email) & Distance == new$Distance & tolower(Skype) == tolower(new$Skype) & Concentration == new$Concentration & desiredDate >= new$reservationDate)
		
		
		if (nrow(ov) > 0 & nrow(pre) ==  0) {
			if(verbose) cat("Guide: Someone else already reserved the slot you are interested in. Please choose a different time.\n")
			res <- "Invalid"
		} else if(nrow(pre) > 0) {
			if(verbose) cat("Guide: If you want to cancel your reservation, you may now do so by choosing the appropriate action.\n")
			res <- "Can cancel"
		} else if (nrow(gotone) > 0){
			if(verbose) cat("Guide: You already have a scheduled office hour and thus cannot make a second reservation. Please come back after your office hour.\n")
			res <- "Invalid"
		} else if (new$Description == "Fill out" | nchar(new$Description) < 20) {
			if(verbose) cat("Guide: Please describe your problem. The description has to be at least 20 characters long.\n")
		} else {
			if(verbose) cat("Guide: You may now proceed to submitting your reservation.\n")
			res <- "Complete"
		}
	}
	return(res)
}

## Construct dates for the calendar
constructDate <- function(x) {
	y <- as.POSIXlt(x)
	year <- as.character(y$year + 1900)
	tmp <- as.character(y$mon + 1)
	mon <- ifelse(nchar(tmp) == 1, paste0(c("0", tmp), collapse=""), tmp)
	tmp <- as.character(y$mday)
	mday <- ifelse(nchar(tmp) == 1, paste0(c("0", tmp), collapse=""), tmp)
	tmp <- as.character(y$hour)
	hour <- ifelse(nchar(tmp) == 1, paste0(c("0", tmp), collapse=""), tmp)
	tmp <- as.character(y$min)
	minute <- ifelse(nchar(tmp) == 1, paste0(c("0", tmp), collapse=""), tmp)
	
	paste0(year, mon, mday, "T", hour, minute, "00")
}

## Build calendar
calendarBuild <- function(file, reservations, public=TRUE) {
	reservations <- reservations[!is.na(reservations$TA), ]
	sink(file)
	cat("BEGIN:VCALENDAR\n")
	cat("VERSION:2.0\n")
	cat("PRODID:-//JHSPH//MPHcapstone//EN\n")
	for (i in seq_len(nrow(reservations))) {
		stamp <- constructDate(reservations$reservationDate[i])
		start <- constructDate(reservations$desiredDate[i])
		end <- constructDate(reservations$desiredDate[i] + 30 * 60)
	
		cat("BEGIN:VEVENT\n")
		if(public) {
			cat(paste("SUMMARY: TA", reservations$TA[i], "Student", reservations$Student[i], "Location", assignRoom(reservations$TA[i], reservations$desiredDate[i]), "\n", sep=" "))
		} else {
			cat(paste("SUMMARY:", reservations$Student[i], reservations$Email[i], reservations$Skype[i], reservations$Concentration[i], assignRoom(reservations$TA[i], reservations$desiredDate[i]), "\n", sep=" "))
		}
		
		cat(paste0("DTSTAMP:", stamp, "\n"))
		cat(paste0("DTSTART;TZID=US/Eastern:", start, "\n"))
		cat(paste0("DTEND;TZID=US/Eastern:", end, "\n"))
		cat("END:VEVENT\n")
	}
	cat("END:VCALENDAR")
	cat("\n")
	sink()
    drop_upload(file, dest = "github/MPHcapstoneTA/www", dtoken = token)
}



## Build email msg
buildEmail <- function(new, action="confirm", verbose=TRUE, email=TRUE) {
	tentative <- ifelse(action == "confirm", "*confirmed* ", "*cancelled* ")
	msg <- buildMsg(new, tentative)
	
	msg <- paste0(msg, "\n\nProblem description:\n", new$Description)
	if(action=="confirm") {		
		msgStudent <- paste0(msg, "\n\nIf for some reason you need to cancel your reservation (minimum 24 hrs notice), please do so through https://lcolladotor.shinyapps.io/MPHcapstoneTA/. You will have to choose the TA, office hour, enter your name, email and MPH concentration (to verify your identity) in order to cancel.")
		subject <- paste("New TA reservation:", as.character(as.Date(new$desiredDate, tz="America/New_York")), "at", new$officeHour)
	} else {
		subject <- paste("Cancelled TA reservation:", as.character(as.Date(new$desiredDate, tz="America/New_York")), "at", new$officeHour)
		msgStudent <- paste0(msg, "\n\n Hopefully everything is ok. Please try to minimize as much as the number of times you have to cancel a TA office hour reservation.")
	}
	
	if(email) {
		msg <- paste0("Reservation details\n-------------------------------\n\n", msg, "\n\n-------------------------------\nPlease do not reply to this email address as no one is checking it.")
	} else {
		msg <- paste0("Reservation details\n-------------------------------\n\n", msg, "\n\n-------------------------------\n\n")
	}
	
	# msgStudent <- paste0(msgStudent, "\n\n-------------------------------\nPlease do not reply to this email address as no one is checking it.")
	
	## Send emails
#	cat(taemails$email[taemails$ta == new$TA])
#	cat(msg)
#	cat(paste0("<", new$Email, ">"))
	if(verbose) {
		cat("\n\n")
		cat(msgStudent)
	}
	res <- list(to=taemails$email[taemails$ta == new$TA], subject=subject, msg=msg, from = NA)
	return(res)
}

## Send email
confirmEmail <- function(from, to, subject, msg) {
## will not work unless address is @gmail.com
#	sendmail(from, to=paste0("<", new$Email, ">"), subject=subject, msg=msgStudent, control=list(smtpServer="ASPMX.L.GOOGLE.COM"))
	from <- sprintf("<mphcapstoneta@gmail.com>")
    ## Currently not working (2015-01-20) with sendmailR
	#sendmail(from, to=to, subject=subject, msg=msg, control=list(smtpServer="ASPMX.L.GOOGLE.COM"))
    mail::sendmail(recipient = to, subject = subject, message = msg)
	return("\n")
}



## Load previous data
loadReservationsFunc <- function() {
	if(file.exists("reservations.Rdata") & file.exists('reservationsHist.Rdata')) {
        load('reservationsHist.Rdata')        
        ## Check if it's the latest version
        newHist <- drop_history('github/mphcapstoneta/reservations.rdata', dtoken = token)
        if(!identical(newHist, reservationsHist)) {
            drop_get("github/MPHcapstoneTA/reservations.Rdata", overwrite = TRUE, dtoken = token)
        }        
        load("reservations.Rdata")
	} else {
		reservations <- data.frame("TA"=NA, "Weekday"=NA, "officeHour"=NA, "Student"=NA, "Email"=NA, "Distance"=NA, "Skype"=NA, "reservationDate"=Sys.time() -1, "Concentration"=NA, "Description"=NA, "minimumPossible"=as.POSIXlt(Sys.time() -1, "America/New_York"), "desiredDate"=as.POSIXlt(Sys.time() -1, "America/New_York"), stringsAsFactors=FALSE)
        saveRes(reservations)
	}
	reservations$reservationDate <- as.POSIXlt(reservations$reservationDate, "America/New_York")
	reservations$minimumPossible <- as.POSIXlt(reservations$minimumPossible, "America/New_York")
	#reservations$desiredDate <- as.POSIXlt(reservations$desiredDate, "America/New_York")
	reservations
}




## Main shiny function
shinyServer(function(input, output, session) {
	
	## Load previous data
	loadReservations <- reactive({
		loadReservationsFunc()
	})
	
	## Define a new entry
	newEntry <- reactive({
		data <- data.frame("TA"=input$ta, "Weekday"=input$weekday, "officeHour"=input$hour, "Student"=input$name, "Email"=input$email, "Distance"=input$distance, "Skype"=input$skype, "reservationDate"=as.POSIXlt(Sys.time(), "America/New_York"), "Concentration" = input$concentration, "Description"=input$description, stringsAsFactors=FALSE)
		data$minimumPossible <- data$reservationDate + 60 * 60 * 24 * 1
		data$desiredDate <- getDesiredDate(data)
		data
	})
	
	## Display other reservations
	output$previous <- renderDataTable({
		new <- newEntry()
		reservations <- loadReservationsFunc()		
		preDisplay <- subset(reservations, desiredDate >= new$reservationDate)[, c("TA", "Student", "Weekday", "officeHour", "desiredDate")]
		preDisplay <- preDisplay[order(preDisplay$desiredDate), ]
		preDisplay$desiredDate <- as.character(as.Date(preDisplay$desiredDate, tz="America/New_York"))
		colnames(preDisplay) <- c("TA", "Student Name", "Weekday", "Office hour", "Date")
		
		if(nrow(preDisplay) == 0) {
			preDisplay <- data.frame("TA"="none", "Student Name"="none", "Weekday"="none", "Office Hour"="none", "Date"="none")
		}
		preDisplay		
	})
	
	## Display entry
	output$yourEntry <- renderPrint({
		new <- newEntry()
		msg <- buildMsg(new)
		cat(msg)
	})
		
	## Verify the reservation entry
	output$checkEntry <- renderPrint({
		new <- newEntry()
		reservations <- loadReservations()

		check <- checkEntry(new, reservations)
		#cat(paste(c("Entry status:", check)))			
	})
	
	## Entry submission
	output$verification <- renderPrint({
		new <- newEntry()
		reservations <- loadReservations()

		check <- checkEntry(new, reservations, verbose=FALSE)
		
		if(check == "Can cancel" & input$reserve %in% c("Cancel reservation", "Cancellation registered")) {
			cat("Confirmation message:\n\n")
			emailInfo <- buildEmail(new, "cancel")
			if(input$reserve == "Cancel reservation") {
				reservations <- loadReservationsFunc()
				idx <- with(reservations, which(TA == new$TA & Student == new$Student & Email == new$Email & Distance == new$Distance & Skype == new$Skype & Concentration == new$Concentration & desiredDate == new$desiredDate))
				reservations <- reservations[-idx, ]
				
				## Update calendar
				calendarBuild("www/publicCalendar.ics", reservations, TRUE)	
				
				## Update TA-individual calendar
				calendarBuild(paste0("www/publicCalendar-", new$TA, ".ics"), subset(reservations, TA == new$TA), TRUE)
						
				## Send email				
				conf <- confirmEmail(emailInfo$from, emailInfo$to, emailInfo$subject, emailInfo$msg)
				#cat(conf)
				
				## Create backup just in case
                saveRes(reservations, file=paste0("reservations.backup-", Sys.time(), ".Rdata"), dest = "github/MPHcapstoneTA/backups")
				
				## Save changes
				saveRes(reservations)
							
				## Finish
				updateSelectInput(session, "reserve", choices="Cancellation registered", selected="Cancellation registered")
			}			
			cat("\n\nYou have successfully cancelled your reservation. You can verify this on the 'Current reservations' tab: your reservation will no longer appear on the current slots taken.")
			
			
			
		} else if(check == "Complete" & input$reserve %in% c("Submit reservation", "Reservation submitted")) {
			cat("Confirmation message:\n\n")
			emailInfo <- buildEmail(new, "confirm")
			if(input$reserve == "Submit reservation") {
				reservations <- loadReservationsFunc()
				reservations <- rbind(reservations, new)
				
				## Update calendar
				calendarBuild("www/publicCalendar.ics", reservations, TRUE)	
				
				## Update TA-individual calendar
				calendarBuild(paste0("www/publicCalendar-", new$TA, ".ics"), subset(reservations, TA == new$TA), TRUE)
						
				## Send email				
				conf <- confirmEmail(emailInfo$from, emailInfo$to, emailInfo$subject, emailInfo$msg)
				#cat(conf)
				
				## Create backup just in case
				saveRes(reservations, file=paste0("reservations.backup-", Sys.time(), ".Rdata"), dest = "github/MPHcapstoneTA/backups")
				
				## Save changes
				saveRes(reservations)
			
				## Finish
				updateSelectInput(session, "reserve", choices="Reservation submitted", selected="Reservation submitted")
			}	
			cat("\n\nYou have successfully completed your office hour reservation. You can verify this on the 'Current reservations' tab: your reservation will appear on the current slots taken.")
        } else if (input$reserve %in% c("Submit reservation", "Cancel reservation")) {
            updateSelectInput(session, "reserve", choices=c("", "Submit reservation", "Cancel reservation"), selected = "")
        }
	})
	
	## Create a link to the messsage for students to download
	output$message <- renderUI({
		new <- newEntry()
		reservations <- loadReservations()

		check <- checkEntry(new, reservations, verbose=FALSE)
		if(input$reserve %in% c("Cancellation registered", "Reservation submitted")) {
			if(check == "Can cancel") {
				emailInfo <- buildEmail(new, "cancel", verbose=FALSE, email=FALSE)
			} else if(check == "Complete") {
				emailInfo <- buildEmail(new, "confirm", verbose=FALSE, email=FALSE)
			}
			## Create link to message for students to download
			confFile <- paste0("messages/", as.character(as.Date(Sys.time())), "-", as.character(round(runif(1, 1e14, 1e15 - 1), 0)), ".txt")
			sink(paste0("www/", confFile))
			cat(emailInfo$msg)
			sink()
			HTML(paste0("Download <a href='https://lcolladotor.shinyapps.io/MPHcapstoneTA/", confFile, "'>confirmation information</a>."))
		} else{
			HTML("")	
		}
		
	})
	
	## Update TA options
	observe({
		choices <- TAchoices[[input$weekday]]
		updateSelectInput(session, "ta", choices=choices, selected=choices[[1]][1])
	})
	
	## Update office hour options
	observe({
		choices <- TAhour[[input$ta]][[input$weekday]]
		## Special cases for Spring Break
#		if(input$ta %in% c("Kevin", "Leo", "Molly", "Therri")) {
#			new <- newEntry()
#			if( as.character(as.Date(new$desiredDate, tz="America/New_York")) %in% c("2014-03-15", "2014-03-16", "2014-03-17", "2014-03-18", "2014-03-19", "2014-03-20", "2014-03-21", "2014-03-22", "2014-03-23")) {
#			choices <- c("00:00")
#			}
#		}
        ## Special case for Youssef switching hours in the middle of 2016
#        if(input$ta == 'Youssef') {
#            new <- newEntry()
#            if( as.character(as.Date(new$desiredDate, tz = 'America/New_York')) %in% c('2016-03-31', '2016-04-01'))
#                choices <- c('00:00')
#        }

		updateSelectInput(session, "hour", choices=choices, selected=choices[1])
	})
	
	## View recent details
	output$recent <- renderDataTable({
		if(input$tapass == tapass) {
			new <- newEntry()
			reservations <- loadReservationsFunc()		
			preDisplay <- subset(reservations, desiredDate >= new$reservationDate - input$farback * 24 * 60^2)[, c("TA", "desiredDate", "Weekday", "officeHour", "Student", "Email", "Distance", "Skype", "Concentration", "Description")]
			preDisplay <- preDisplay[order(preDisplay$desiredDate), ]
			preDisplay$desiredDate <- as.character(as.Date(preDisplay$desiredDate, tz="America/New_York"))
			colnames(preDisplay) <- c("TA", "Date", "Weekday", "Office hour", "Student", "Email", "Distance", "Skype", "Concentration", "Description")
			
			if(nrow(preDisplay) == 0) {
				preDisplay <- data.frame("TA"="none", "Date"="none", "Weekday"="none", "Office hour"="none", "Student"="none", "Email"="none", "Distance"="none", "Skype"="none", "Concentration"="none", "Description"="none")
			}
		} else {
			preDisplay <- data.frame("Restricted"="yes", "Access"="Failed", stringsAsFactors=FALSE)
		}
		preDisplay
	})
	
	## All reservations
	output$taData <- downloadHandler(
	    filename  <-  function() { 'MPHcapstoneTAreservations2016.csv' },
	    content  <-  function(file) {
			if(input$tapass == tapass) {
				data <- loadReservationsFunc()
				data <- data[!is.na(data$TA), ]
			} else {
				data <- data.frame("NoAccess"="EnterPassword", stringsAsFactors="FALSE")
			}
			write.csv(data, file)
			
	    }
	)
	output$taRData <- downloadHandler(
	    filename  <-  function() { 'reservations.Rdata' },
	    content  <-  function(file) {
			if(input$tapass == tapass) {
				data <- loadReservationsFunc()
				data <- data[!is.na(data$TA), ]
			} else {
				data <- data.frame("NoAccess"="EnterPassword", stringsAsFactors="FALSE")
			}
            reservations <- data
			save(reservations, file = file)
			
	    }
	)
	
	## Calendar
	output$calendar <- downloadHandler(
		filename <- "MPHofficeHours.ics",
		content <- function(file) {
			if(input$tapass == tapass) {
				reservations <- loadReservationsFunc()
				## Filter selected TA
				if(input$taname != "All") {
					reservations <- subset(reservations, TA == input$taname)
				}
			
				## Write the calendar
				calendarBuild(file, reservations, FALSE)
			} else {
				data <- data.frame("Access"="Not verified")
				write.csv(data, file)
			}
		}	
	)
	
	## Show current time
	output$currentTime <- renderPrint({
		x <- Sys.time()
		print(as.POSIXlt(x, tz = "America/New_York"), quote=FALSE)
	})
	
	## Debug time
	output$debugT <- renderPrint({
		new <- newEntry()
		reservations <- loadReservations()
		
		print(new$desiredDate)
		cat("\n-----\n")
		print(reservations$desiredDate)
	})
	
}) 