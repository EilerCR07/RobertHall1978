######################################################

# Title: Macroeconomics Midterm
# subtitle: Robert Hall 1978 Table One

# author: Chris R. Eiler

######################################################

# clear the work space
rm(list = ls())

# load required packages
require(xlsx)
require(ggplot2)
require(quantmod)
require(lmtest)

# set working directory
setwd('G:/Macroeconomics/RawData')

# load datasets
Population <- read.csv('Population.csv', header = TRUE)
NIPA <- xlsx::read.xlsx('NIPA115.xlsx', sheetIndex = 1, header = TRUE)
PriceDeflator <- xlsx::read.xlsx('NIPA119.xlsx', sheetIndex = 1, header = TRUE)

# munge NIPA
	# delete superfluous information
NIPA <- subset(NIPA[5:nrow(NIPA), ])
	# transpose the dataset
NIPA <- t(NIPA)
	# rename the columns
colnames(NIPA) <- NIPA[2, ]
	# delete repetitive information
NIPA <- subset(NIPA[3:nrow(NIPA), ])
	# define the year
Date <- seq(from = 1947, to = 2016.5, by = 0.25)
Date <- substr(Date, 1, 4)
NIPA <- cbind(NIPA, Date)
	# make NIPA and data frame
NIPA <- as.data.frame(NIPA)
	# make Year numeric
Year <- as.numeric(NIPA$Date)
Year <- Year + 1946
NIPA <- cbind(NIPA, Year)

# munge PriceDeflator
	# delete superfluous information
PriceDeflator <- subset(PriceDeflator[5:nrow(PriceDeflator), ])
	# transpose the dataset
PriceDeflator <- t(PriceDeflator)
	# rename the columns
colnames(PriceDeflator) <- PriceDeflator[2, ]
	# delete repetitive information
PriceDeflator <- subset(PriceDeflator[3:nrow(PriceDeflator), ])
PriceDeflator <- cbind(PriceDeflator, Date)
	# make PriceDeflator and data frame
PriceDeflator <- as.data.frame(PriceDeflator)
	# make Year numeric
Year <- as.numeric(NIPA$Date)
Year <- Year + 1946
PriceDeflator <- cbind(PriceDeflator, Year)
	# rename columns
colnames(PriceDeflator )[8] <- 'NondurablesDeflator'
colnames(PriceDeflator )[9] <- 'ServicesDeflator'
PriceDeflator <- subset(PriceDeflator[ ,c(8, 9)])
	# scale population
Population$NationalPopulation <- Population$NationalPopulation * 1000

# munge Population
colnames(Population)[2] <- 'NationalPopulation'
Population$Quarter <- rep(seq(from = 1, to = 4, by = 1), length.out = nrow(Population))
Population$Year <- substr(Population$DATE, 1, 4)
Population$Year <- as.numeric(Population$Year)

# merge Census dataset and NIPA dataset
NIPA <- cbind(NIPA, PriceDeflator)
	# make quarters to merge by Year and Quarter
NIPA$Quarter <- rep(seq(from = 1, to = 4, by = 1), length.out = nrow(NIPA))
Hall <- merge(Population, NIPA, by = c('Year', 'Quarter'))

# define Hall's consumption
	# rename columns
colnames(Hall)[11] <- 'Nondurables'
colnames(Hall)[12] <- 'Services'
	# make factors into numerics
Hall$NondurablesDeflator <- as.numeric(as.character(Hall$NondurablesDeflator))
Hall$ServicesDeflator <- as.numeric(as.character(Hall$ServicesDeflator))
Hall$Nondurables <- as.numeric(as.character(Hall$Nondurables))
Hall$Services <- as.numeric(as.character(Hall$Services))
	# scale the consumption numbers up
Hall$Nondurables <- Hall$Nondurables * 1000000000
Hall$Services <- Hall$Services * 1000000000
	# get in real terms
Hall$RealNondurables <- Hall$Nondurables / Hall$NondurablesDeflator / 100
Hall$RealServices <- Hall$Services / Hall$ServicesDeflator / 100
	# define
Hall$HallConsumption <- Hall$RealNondurables + Hall$RealServices
Hall$PerCapitaReal <- Hall$HallConsumption / Hall$NationalPopulation

# only use the years Robert Hall used
Hall77 <- subset(Hall[!(Hall$Year > 1977), ])
Hall77 <- subset(Hall[!(Hall$Year < 1948), ])

# Develop the models
# AR(1)
AR <- stats::ar(Hall77$PerCapitaReal, method = 'ols')

# define variables
Hall77$Ct.02 <- Hall77$PerCapitaReal ^ (-(5))
Hall77$Ct.02Lag <- quantmod::Lag(x = Hall77$Ct.02, k = 1)
Hall77$Ct.inv <- Hall77$PerCapitaReal ^ (-1)
Hall77$Ct.invLag <- quantmod::Lag(x = Hall77$Ct.inv, k = 1)
Hall77$Ct.1 <- Hall77$PerCapitaReal
Hall77$Ct.1Lag <- quantmod::Lag(x = Hall77$Ct.1, k = 1)

# declare the time series
Hall77$ID <- seq(from = 1, to = nrow(Hall77), by = 1)
Hall77$ID <- ts(Hall77$ID)

# OLS
	# sigma = 0.2
Hall.Model.1 <- lm(Hall77$Ct.02 ~ Hall77$Ct.02Lag - 1)
summary(Hall.Model.1)
	# model's standard error
resid.1 <- Hall.Model.1$resid
resid.1.sq <- resid.1 ^ 2
resid.1.sq.sum <- sum(resid.1.sq)
sigma.1 <- sqrt(resid.1.sq.sum / (nrow(Hall) - 1))
print(sigma.1)
	# Durbin - Watson test
lmtest::dwtest(Hall77$Ct.02 ~ Hall77$Ct.02Lag - 1)
	# sigma = 1
Hall.Model.2 <- lm(Hall77$Ct.inv ~ Hall77$Ct.invLag - 1)
summary(Hall.Model.2)
	# model's standard error
resid.2 <- Hall.Model.2$resid
resid.2.sq <- resid.2 ^ 2
resid.2.sq.sum <- sum(resid.2.sq)
sigma.2 <- sqrt(resid.2.sq.sum / (nrow(Hall) - 1))
print(sigma.2)
	# Durbin - Watson test
lmtest::dwtest(Hall77$Ct.inv ~ Hall77$Ct.invLag - 1)
	# sigma = -1
Hall.Model.3 <- lm(Hall77$Ct.1 ~ Hall77$Ct.1Lag)
summary(Hall.Model.3)
	# model's standard error
resid.3 <- Hall.Model.3$resid
resid.3.sq <- resid.3 ^ 2
resid.3.sq.sum <- sum(resid.3.sq)
sigma.3 <- sqrt(resid.3.sq.sum / (nrow(Hall) - 2))
print(sigma.3)
	# Durbin - Watson test
lmtest::dwtest(Hall77$Ct.1 ~ Hall77$Ct.1Lag)

# plot PerCapitaReal
ggplot2::ggplot(Hall77, aes(x = ID, y = PerCapitaReal)) +
	geom_line(size = 1, col = 'darkorange') +
	geom_point(col = 'darkblue') +
	xlab('period') +
	ylab('real consumption [nondurables & services]') +
	ggtitle(expression(atop('Consumption Over Time', atop(italic('1948 - 1977')))))

# declare the time series
Hall$ID <- seq(from = 1, to = nrow(Hall), by = 1)
Hall$ID <- ts(Hall$ID)

# Develop the models
# AR(1)
AR <- stats::ar(Hall$PerCapitaReal, method = 'ols')

# define variables
Hall$Ct.02 <- Hall$PerCapitaReal ^ (-(5))
Hall$Ct.02Lag <- quantmod::Lag(x = Hall$Ct.02, k = 1)
Hall$Ct.inv <- Hall$PerCapitaReal ^ (-1)
Hall$Ct.invLag <- quantmod::Lag(x = Hall$Ct.inv, k = 1)
Hall$Ct.1 <- Hall$PerCapitaReal
Hall$Ct.1Lag <- quantmod::Lag(x = Hall$Ct.1, k = 1)

# OLS
	# sigma = 0.2
Hall.Model.1 <- lm(Hall$Ct.02 ~ Hall$Ct.02Lag - 1)
summary(Hall.Model.1)
	# model's standard error
resid.1 <- Hall.Model.1$resid
resid.1.sq <- resid.1 ^ 2
resid.1.sq.sum <- sum(resid.1.sq)
sigma.1 <- sqrt(resid.1.sq.sum / (nrow(Hall) - 1))
print(sigma.1)
	# Durbin - Watson test
lmtest::dwtest(Hall$Ct.02 ~ Hall$Ct.02Lag - 1)
	# sigma = 1
Hall.Model.2 <- lm(Hall$Ct.inv ~ Hall$Ct.invLag - 1)
summary(Hall.Model.2)
	# model's standard error
resid.2 <- Hall.Model.2$resid
resid.2.sq <- resid.2 ^ 2
resid.2.sq.sum <- sum(resid.2.sq)
sigma.2 <- sqrt(resid.2.sq.sum / (nrow(Hall) - 1))
print(sigma.2)
	# Durbin - Watson test
lmtest::dwtest(Hall$Ct.inv ~ Hall$Ct.invLag - 1)
	# sigma = -1
Hall.Model.3 <- lm(Hall$Ct.1 ~ Hall$Ct.1Lag)
summary(Hall.Model.3)
	# model's standard error
resid.3 <- Hall.Model.3$resid
resid.3.sq <- resid.3 ^ 2
resid.3.sq.sum <- sum(resid.3.sq)
sigma.3 <- sqrt(resid.3.sq.sum / (nrow(Hall) - 2))
print(sigma.3)
	# Durbin - Watson test
lmtest::dwtest(Hall$Ct.1 ~ Hall$Ct.1Lag)
