## Setup
source("server.R")

## Specify layout
shinyUI(pageWithSidebar(
	
	headerPanel(HTML("MPH capstone TA office hours - 2014 version")),
	
	
	sidebarPanel(
		## Construct input options
		
		## Choose the data
		h4("TA information"),
		
		## Weekday
		selectInput("weekday", "Weekday", c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")),	
		
		## Choose TA
		selectInput("ta", "TA", c("Choose a TA", "Megan Clayton" = "Megan", "Leonardo Collado Torres" = "Leo", "Kevin Fain" = "Kevin", "Amy Paul" = "Amy", "Molly Simmons" = "Molly", "Therri Usher" = "Therri")),
		
		#### TA info
		## TA: Megan
		conditionalPanel(
			condition = "input.ta == 'Megan'",
	
			## Area of focus
			helpText("Areas of focus: qualitative research, social and behavioral sciences, and food systems"),
			tags$hr(),
			HTML("Available: Tuesdays & Wednesdays")
		),

		## TA: Leo
		conditionalPanel(
			condition = "input.ta == 'Leo'",
	
			## Area of focus
			helpText("Areas of focus: biostatistics, genomics"),
			tags$hr(),
			HTML("Available: Wednesdays & Fridays")
		),

		## TA: Kevin
		conditionalPanel(
			condition = "input.ta == 'Kevin'",
	
			## Area of focus
			helpText("Areas of focus: epidemiology, environmental health & risk assessment, and health & regulatory policy"),
			tags$hr(),
			HTML("Available: Mondays & Tuesdays")
		),

		## TA: Amy
		conditionalPanel(
			condition = "input.ta == 'Amy'",
	
			## Area of focus
			helpText("Areas of focus: bioethics, health policy, qualitative research, and global health"),
			tags$hr(),
			HTML("Available: Mondays & Tuesdays")
		),

		## TA: Molly
		conditionalPanel(
			condition = "input.ta == 'Molly'",
	
			## Area of focus
			helpText("Areas of focus: health policy, qualitative research, mental health, injury prevention & research, and political analysis"),
			tags$hr(),
			HTML("Available: Tuesdays")
		),

		## TA: Therri
		conditionalPanel(
			condition = "input.ta == 'Therri'",
	
			## Area of focus
			helpText("Areas of focus: biostatistics, health disparities, and aging"),
			tags$hr(),
			HTML("Available: Mondays & Wednesdays")
		),
		
		## Office hour
		selectInput("hour", "Time", c("00:00")),
	
		tags$hr(),
		h4("Your information"),
		
		textInput("name", "Name", "Your name"),
		textInput("email", "Email", "Your email"),
		selectInput("distance", "Are you a distance student?", c("No", "Yes")),
		conditionalPanel(
			condition = "input.distance == 'Yes'",
			textInput("skype", "Skype username", "")
		),
		selectInput("concentration", "Which is your MPH concentration?", c(
			"Choose your concentration",
			"1. MPH Customized Program of Study",
			"2. Child & Adolescent Health",
			"3. Epidemiologic & Biostatistics Methods for Public Health & Clinical Research",
			"4. Food, Nutrition, & Health",
			"5. Global Environmental Sustainability & Health",
			"6. Health in Crisis & Humanitarian Assistance",
			"7. Health Leadership & Management",
			"8. Health Systems & Policy",
			"9. Infectious Diseases",
			"10. Social & Behavioral Sciences in Public Health",
			"11. Women's & Reproductive Health"
		)),
		tags$hr(),
		h4("Description of your problem"),
		tags$textarea(id="description", rows=5, cols=50, "Fill out"),
		helpText("Describe your project topic and what help is needed. If using STATA or other software be *VERY SPECIFIC* about what type of analysis you are doing, and document any error messages you need to inquire about."),
		helpText("Your description should be at least 20 characters long."),
		tags$hr(),
		h4("Final step"),
		selectInput("reserve", "Action to perform", c("", "Submit reservation", "Cancel reservation")),
		helpText("Verify that you see the confirmation of your reservation/cancellation."),
		HTML("You must <a href='http://glimmer.rstudio.com/lcolladotor/MPHcapstoneTA/'>reload the site</a> to perform another action.")
		
	),
		
	mainPanel(
		tabsetPanel(
			## TA assigned calendar
			tabPanel("Reservation details",
				h4("TA hours report"),
				HTML("We invite you to read the <a href='http://lcolladotor.github.io/mphtasessions/'>TA hours report</a>. Enjoy it!"),
				h4("Important rules!"),
				tags$b("You may only have one active reservation at any given time!"),
				tags$p("This ensures that all students have an equal and fair opportunity to sign up for TA sessions and get help, advice, and feedback on their projects."),
				helpText("You need to reschedule? Then please cancel your active reservation before making a second one. Remember that the confirmation message contains all the information you will need to cancel the reservation: the message is specially useful to detect typos that might be stopping you from verifying your identity."),
				h4("Your *tentative* entry"),
				helpText("Please remember to verify the date of your TA session before confirming your reservation!"),
				verbatimTextOutput('yourEntry'),
				h4("Check Entry"),
				verbatimTextOutput('checkEntry'),
				verbatimTextOutput('verification'),
				htmlOutput('message'),
#				verbatimTextOutput('debugT'),
				tags$hr(),
				tags$p("Current time (EST timezone)"),
				verbatimTextOutput('currentTime'),
				helpText("Remember that you can only make reservations with at least 24 hrs notice and a maximum of 7 days before the desired time."),
				tags$hr()
			),
			tabPanel("Current reservations",
				h4("Slots taken"),
				tags$p("These are the currently reserved office hour slots:"),
				dataTableOutput('previous'),
				tags$hr(),
				helpText("You can also view the reserved slots in the public calendar"),
				HTML("<iframe src='https://www.google.com/calendar/embed?title=TA%20public%20calendar&amp;showCalendars=0&amp;mode=AGENDA&amp;height=300&amp;wkst=2&amp;bgcolor=%23FFFFFF&amp;src=pdqn6hl8fgjh2antqkgreo886j6j8oo3%40import.calendar.google.com&amp;color=%232952A3&amp;ctz=America%2FNew_York' style=' border-width:0 ' width='600' height='300' frameborder='0' scrolling='no'></iframe>"),
				helpText("Note that the calendar has a very slow refresh rate due to how Google Calendar works.")
			),			
			tabPanel("TA info",
				h4("Megan Clayton"),
				tags$p("Tuesdays & Wednesdays 9:00-11:00am"),
				helpText("Areas of focus: qualitative research, social and behavioral sciences, and food systems"),				
				h4("Leonardo Collado Torres"),
				tags$p("Wednesdays & Fridays 12:45-2:45pm"),
				helpText("Areas of focus: biostatistics, genomics"),
				h4("Kevin Fain"),
				tags$p("Mondays 1:30-3:30pm & Tuesdays 3:00-5:00pm"),
				helpText("Areas of focus: epidemiology, environmental health & risk assessment, and health & regulatory policy"),
				h4("Amy Paul"),
				tags$p("Mondays 10am-12pm & Tuesdays 11am-1pm"),
				helpText("Areas of focus: bioethics, health policy, qualitative research, and global health"),				
				h4("Molly Simmons"),
				tags$p("Tuesdays 11am-3pm"),
				helpText("Areas of focus: health policy, qualitative research, mental health, injury prevention & research, and political analysis"),
				h4("Therri Usher"),
				tags$p("Mondays 1:15-3:15pm & Wednesdays 12:15-2:15pm"),
				helpText("Areas of focus: biostatistics, health disparities, and aging"),
				tags$hr()
			),
			tabPanel("Instructions (Help)",
				h4("Which are the currently reserved spots?"),
				tags$p("You can view this information on the 'Current reservations' tab."),
				h4("When are the different TA's available? What are their areas of focus?"),
				tags$p("This information is shown under the 'TA info' tab."),
				
				tags$hr(),
				h4("How to submit a reservation"),
				helpText("Note that you can only make reservations with at least 24hrs notice and a maximum of 7 days before the desired date. That is why the date is unambiguous and gets chosen automatically. It will be displayed under 'Your *tentative* entry' in the 'Reservation details' tab. Further note that you can only have one active reservation at a time."),
				tags$p("1. Choose a weekday. This will restrict which TAs you can choose from."),
				tags$p("2. Choose a TA. This will restrict which office hour times are available."),
				tags$p("3. Choose a time."),
				tags$p("4. Enter your name. Example: Testy Test"),
				tags$p("5. Enter your email. Example: test@gmail.com"),
				tags$p("6. If you are a distance student, select the corresponding option. Then enter your Skype ID."),
				tags$p("7. Choose your corresponding MPH concentration. This allows the TA to have a general idea of your background."),
				tags$p("8. If someone else already reserved the time you wanted, a message under 'Check Entry' will inform you of this case and you will have you to choose a different weekday/TA/time."),
				tags$p("9. Fill out the description of your problem."),
				tags$p("10. Check that your entry is valid and make sure that you can make it at the selected date/time."),
				tags$p("11. Select the 'Submit reservation' action. An email will be sent to the corresponding TA to notify them of your reservation along with your details and problem description."),
				tags$p("12. Verify that you see the confirmation."),
				helpText("While you complete the steps, 'Your *tentative* entry' will update itself until it looks like a coherent message. 'Check entry' will also update itself and guide you along the path."),
				
				tags$hr(),
				h4("How to cancel a reservation"),
				helpText("Office hours reservations can only be cancelled with at least 24hrs notice. Please keep this in mind."),
				tags$p("1. Choose the weekday of your reservation."),
				tags$p("2. Choose the TA of your reservation."),
				tags$p("3. Choose the time of your reservation."),
				tags$p("4. Enter your name, exactly how you did it when making the reservation."),
				tags$p("5. Enter your email, exactly how you did it when making the reservation."),
				tags$p("6. If you are a distance student, select the corresponding option. Then enter your Skype ID."),
				tags$p("7. Choose your corresponding MPH concentration."),
				tags$p("8. By filling the previous steps, you have verified your identity. Under 'Check entry' a message will appear notifying you that your reservation was located and can be cancelled."),
				tags$p("9. Cancel the reservation by choosing the corresponding action. An email will be sent to the corresponding TA to notify them of your cancelled reservation."),
							
				tags$hr(),
				h4("How can I make sure that my reservation/cancellation was processed?"),
				tags$p("Check the 'Current reservations' tab. The 'Slots taken' section will have the latest information."),
				
				tags$hr(),
				h4("Why is my reservation/cancellation not updating on the Google Calendar?"),
				tags$p("Google Calendar checks for changes on the .ics file at a very slow refresh rate (can be as slows as every 24hrs) and we cannot change this setting."),
				tags$p("We recommend using the simpler table display in the 'Current reservations' tab to verify that your office hour was reserved/cancelled."),
				tags$hr()				
			),
			tabPanel("For TAs",
				h4("Add the public calendar"),
				helpText("You can add the public calendar to your client by either adding the public Google calendar from the 'Current reservations' tab (refresh rate is very slow) or using your own calendar application and choosing a high refresh rate."),
				helpText("For example, in a Mac you can use the 'Calendar' app, then go to 'File' -> 'New calendar subscription ...' -> enter the calendar URL -> choose a refresh rate of every 5 (or 15) minutes."),
				HTML("<a href='http://glimmer.rstudio.com/lcolladotor/MPHcapstoneTA/publicCalendar.ics'>Public calendar URL</a>."),
				h4("Enter the TA password"),
				textInput("tapass", "TA password", ""),
				h4("View details on recent reservations"),
				numericInput("farback", "How many days ago do you want to look?", value=0, min=0, max=90, step=1),
				helpText("It will always show the information for the next 7 days, but maybe in some cases you want to look at older reservations. For example, to check previous sessions from the same student and asses their progress."),
				tags$hr(),
				dataTableOutput("recent"),
				helpText("Requires password to display the information."),
				h4("Download calendar"),
				selectInput("taname", "Select a TA", c("All", "Megan", "Leo", "Kevin", "Amy", "Molly", "Therri")),
				helpText("If you selected a TA, only the events for that TA will appear in the calendar."),
				downloadButton('calendar', 'Download'),
				helpText("TA password is required."),
				h4("Download all reservations"),
				helpText("Generates a CSV file with all the reservations data"),
				downloadButton('taData', 'Download'),
				helpText("TA password is required."),
				tags$hr()
			),
			tabPanel("Credits",
				HTML("Inspired by Alyssa Frazee's <a href='http://biostat.jhsph.edu/~afrazee/mphcapstone.html'>MPH capstone office hour sign-up</a>. This is an attempt to make things more automized and to concentrate all sign up forms in one location."),
				tags$hr(),
				HTML("Powered by <a href='http://www.rstudio.com/shiny/'>Shiny</a> and hosted by <a href='http://www.rstudio.com/'>RStudio</a>."),
				tags$hr(),
				HTML("Developed by <a href='http://bit.ly/LColladoTorres'>L. Collado Torres</a>."),
				HTML("Version 0.0.7. Code hosted by <a href='https://github.com/lcolladotor/MPHcapstoneTA'>GitHub</a>."),
				tags$hr()
			)
			
		)
	)
	
))
