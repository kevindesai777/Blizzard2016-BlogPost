install.packages("openxlsx")
install.packages("splitstackshape")
install.packages("dplyr")
install.packages("stringi")
install.packages("maps")
install.packages("ggmap")
install.packages("rgdal")
install.packages("ggplot2")
install.packages("ggthemes")
install.packages("choroplethr")
install.packages("choroplethrMaps")
install.packages("grid")

x <- c("dplyr","plyr","stringi","splitstackshape","openxlsx", "ggmap","maps","ggplot2","rgdal","ggthemes","grid","choroplethr","choroplethrMaps","gridExtra")
lapply(x, library, character.only = TRUE)

data("county.regions")
data("county.map")
#Cleaning data
data <- read.csv("placestxt.csv", header = FALSE)
data$time <- data$V2
data$city <- data$V1
data <- as.data.frame(data)
data <- subset(data, select = -c(V1,V2))
data <- data[,c("city","time")]
data <- concat.split.multiple(data,"city",seps = ",")
names(data)[names(data) == "city_1"] <- "city"
names(data)[names(data) == "city_2"] <- "state"
data <- subset(data, select = c("city","state","time"))
data <- na.omit(data)

#Separating data into city, state and countries
stateData <- data[stri_length(data$state) == 3]
cityStateData <- data[stri_length(data$state) == 2]
countryData <- data[stri_length(data$state) > 3]

cityStateCount <- ddply(cityStateData,.(city, state),nrow)
cityStateCount <- cityStateCount[order(-cityStateCount$V1),]
cityStateCount <- cityStateCount[-which(cityStateCount$state=="AK"),]
cityStateCount <- cityStateCount[-which(cityStateCount$state=="HI"),]

maxStateCount <- ddply(cityStateData,.(state),nrow)
maxStateCount <- maxStateCount[order(-maxStateCount$V1),]

stateCountData <- ddply(stateData,.(city),nrow)
stateCountData <- stateCountData[order(-stateCountData$V1),]

cityDemo <- paste(cityStateCount$city,cityStateCount$state,sep = ',')
gotSnowCity <- cityDemo
ll.gotSnow <- geocode(as.character(gotSnowCity))

us <- readOGR(dsn="us.geojson", layer="OGRGeoJSON")
ll.gotSnow <- cbind.data.frame(ll.gotSnow,freq = cityStateCount$V1)
saveRDS(ll.gotSnow, file="loc.Rda")

theme_opts <- list(theme(panel.grid.minor = element_blank(),
                         panel.grid.major = element_blank(),
                         panel.background = element_blank(),
                         plot.background = element_rect(fill="#e6e8ed"),
                         panel.border = element_blank(),
                         axis.line = element_blank(),
                         axis.text.x = element_blank(),
                         axis.text.y = element_blank(),
                         axis.ticks = element_blank(),
                         axis.title.x = element_blank(),
                         axis.title.y = element_blank(),
                         plot.title = element_text(size=22)))

# plot map
plot1 <- ggplot(us, aes(long,lat, group=group)) +
  geom_polygon() +
  geom_point(data = ll.gotSnow, inherit.aes=FALSE ,aes(x = lon, y = lat), color = "tomato") +
  labs(title="Tweets talking about Blizzard 2016") + 
  coord_equal() +
  theme_opts

nycBoroughs <- cityStateCount[which(cityStateCount$state=="NY"),]
nycBoroughs <- head(nycBoroughs, n = 5)
nycBoroughsRegion <- subset(nycBoroughs, select = -c(state))
nycBoroughsRegion <- rename(nycBoroughsRegion, c("V1"="value"))
nycBoroughsRegion <- nycBoroughsRegion[order(nycBoroughsRegion$region),]
nycBoroughsRegion$region <- tolower(nycBoroughsRegion$region)
nyc_county_fips = c(36005, 36047, 36061, 36081, 36085)
nycBoroughsRegion["region"] <- nyc_county_fips
nycBoroughsRegion <- subset(nycBoroughsRegion, select = -c(reg))
nycBoroughsActual <- nycBoroughsRegion
nycBoroughsActual["value"] <- c(27.6,27,26.6,27.26,31.3)
tweets <- county_choropleth(nycBoroughsRegion, 
                  title       = "Tweets in NYC Boroughs",
                  legend      = "Number of Tweets",
                  num_colors  = 5,
                  county_zoom = nyc_county_fips) +
                  scale_fill_brewer(palette=7)

actual <- county_choropleth(nycBoroughsActual, 
                title = "Average Snowfall in each Borough",
                legend = "Avg. Snowfall in inches",
                num_colors = 5,
                county_zoom = nyc_county_fips) +
                scale_fill_brewer(palette=7)


countryDataCount <- ddply(countryData,.(city, state),nrow)
maxCountryDataCount <- ddply(countryDataCount,.(state),nrow)
maxCountryDataCount <- maxCountryDataCount[order(-maxCountryDataCount$V1),]


ll.world <- geocode(as.character(maxCountryDataCount$state))
world.x <- ll.world$lon
world.y <- ll.world$lat

mp <- NULL
mapWorld <- borders("world", colour="gray50", fill="gray50") # create a layer of borders
mp <- ggplot() +   mapWorld
mp <- mp+ geom_point(aes(x=world.x, y=world.y), color = "tomato") + theme_opts
mp

#convert state names to abbreeviations
stateCountData$city <- state.abb[match(stateCountData$city,state.name)]
stateCountData <- stateCountData[order(stateCountData$city),]
maxStateCount <- maxStateCount[order(maxStateCount$state),]
stateCountData <- rename(stateCountData, c("city"="state"))

totalStateCount <- merge(maxStateCount,stateCountData,by="state")
totalStateCount$V1.x <- totalStateCount$V1.x + totalStateCount$V1.y
totalStateCount <- subset(totalStateCount, select = -c(V1.y))
totalStateCount <- rename(totalStateCount, c("V1.x"="numTweets"))
totalStateCount <- totalStateCount[order(-totalStateCount$numTweets),]
totalStateCount <- head(totalStateCount, n = 6)
grid.table(totalStateCount)

state <- c("WV","VA","MD","PA","NJ","NY")
avgSnowfall <- c(41.25,39,38.5,38.3,33,31.3)
snowfallByState <- as.data.frame(cbind(state,avgSnowfall))
grid.table(snowfallByState)
