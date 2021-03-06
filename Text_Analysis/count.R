#install.packages("plyr")
#install.packages("dplyr")
#install.packages("/home/marisa/R/koRpus_0.06-5.tar.gz", repos = NULL, type = "source")
#install.packages("stringr")

library("plyr")
library("dplyr")
library("koRpus")
library("stringr")

####################################
# Analysis Functions
####################################

get.tagged.text <- function(article) {

  article <- as.character(article)

  file.connection <- file("/home/marisa/tmp/count/tmp.txt")
  writeLines(article, file.connection)
  close(file.connection)

  tagged.text <- treetag("/home/marisa/tmp/count/tmp.txt", treetagger="manual", lang="de", TT.options=list(path="/home/marisa/TreeTagger", preset="de-utf8"))
  return(tagged.text)
}

get.word.count = function(tagged.text, length) {

  tagged.text.df <- taggedText(tagged.text)
  map = data.frame(tagged.text.df, count=1, length=length)

  analysed.text <- summarize(group_by(map, lemma, wclass, length), abs_count = n(), rel_count = n()/length[1])
  return(analysed.text)
}

get.filtered.POS.text = function (tagged.text, focus="") {

  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "punctuation")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "fullstop")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "conjunction")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "article")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "comma")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "preposition")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "pronoun")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "number")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "particle")
  tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = " c o m p o s i t i o n ")

  if(focus == "adjective") {
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "name")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adverb")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "noun")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "verb")
  }

  if(focus == "noun") {
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adjective")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "verb")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "name")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adverb")
  }

  if(focus == "verb") {
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adjective")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "name")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adverb")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "noun")
  }
  if(focus == "adverb") {
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adjective")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "noun")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "name")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "verb")
  }
  if(focus == "name") {
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adjective")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "noun")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "verb")
    tagged.text <- kRp.filter.wclass(tagged.text, corp.rm.class = "adverb")
  }
  return(tagged.text)
}

analyse.word.count = function(text, focus="") {

  tagged.text <- get.tagged.text(text)

  full_length = length(taggedText(tagged.text)$token)

  filtered.tagged.text <- get.filtered.POS.text(tagged.text, focus)
  count <- get.word.count(filtered.tagged.text, full_length)
  return (count)
}

analyse.all = function(data, filepath, focus="") {

  for(i in 1:length(data$article)) {
    result <- analyse.word.count(data$article[i], focus)
    result.df <- data.frame(result, year=data$year[i], month=data$month[i])
    result.df <- result.df[order(-result.df$ a b s _ c o u n t ), ]
    write.csv(result.df, file=paste(filepath, data$year[i], data$month[i], ".csv"), row.names=TRUE, fileEncoding = "UTF-16LE")
  }
}

####################################
# -1- Data Preparation
####################################

##SPON
# Load CSV File
data.SPON <- read.csv("/share/Data/SPON_complete", encoding="UTF-16LE", header = TRUE, sep = ",", quote = "\"", dec = ".", fill = TRUE, comment.char = "")

# Split String into Day, Month, Year
data.SPON$year = laply(data.SPON$day, function(date) unlist(str_split(date, '\\.'))[3])
data.SPON$month = laply(data.SPON$day, function(date) unlist(str_split(date, '\\.'))[2])
data.SPON$day = laply(data.SPON$day, function(date) unlist(str_split(date, '\\.'))[1])

# Convert Factor to String
data.SPON$article <- laply(data.SPON$article, as.character)
data.SPON <- filter(data.SPON, data.SPON$article != "")

##JF
# Load CSV File
data.JF <- read.csv("/share/DATA/jungefreiheit.csv", encoding="UTF-16LE", header = TRUE, sep = ",", quote = "\"", dec = ".", fill = TRUE, comment.char = "")

# Split String into Day, Month, Year
data.JF$year = laply(data.JF$day, function(date) unlist(str_split(date, '\\.'))[3])
data.JF$month = laply(data.JF$day, function(date) unlist(str_split(date, '\\.'))[2])
data.JF$day = laply(data.JF$day, function(date) unlist(str_split(date, '\\.'))[1])

# Convert Factor to String
data.JF$article <- laply(data.JF$article, as.character)
data.JF <- filter(data.JF, data.JF$article != "")

####################################
# -2- Data Analysis / Result Processing + Saving
####################################

#####################################
########### All Catagories ##########
#####################################

catagory = "All"
# Analysis for all Catagory
# Grouped by Year and Month

#####################################
# Part-Of-Speech adjective, verb, adverb, noun, name
#####################################

focus = "all"

##SPON
data.SPON.grouped = summarise(group_by(data.SPON, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"))

##JF
data.JF.grouped = summarise(group_by(data.JF, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"))

#####################################
# Part-Of-Speech adjective
#####################################

focus = "adjective"

##SPON
data.SPON.grouped = summarise(group_by(data.SPON, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), focus)

##JF
data.JF.grouped = summarise(group_by(data.JF, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), focus)

#####################################
# Part-Of-Speech noun
#####################################

focus = "noun"

##SPON
data.SPON.grouped = summarise(group_by(data.SPON, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), focus)

##JF
data.JF.grouped = summarise(group_by(data.JF, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), focus)

#####################################
# Part-Of-Speech verb
#####################################

focus = "verb"

##SPON
data.SPON.grouped = summarise(group_by(data.SPON, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), focus)

##JF
data.JF.grouped = summarise(group_by(data.JF, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), focus)

#####################################
# Part-Of-Speech adverb
#####################################

focus = "adverb"

##SPON
data.SPON.grouped = summarise(group_by(data.SPON, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), focus)

##JF
data.JF.grouped = summarise(group_by(data.JF, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), focus)

#####################################
# Part-Of-Speech name
#####################################

focus = "name"

##SPON
data.SPON.grouped = summarise(group_by(data.SPON, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), focus)

##JF
data.JF.grouped = summarise(group_by(data.JF, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), focus)

#####################################
############## Politik ##############
#####################################

# Analysis for Catagory "Politik"
# Grouped by Year and Month
catagory = "Politik"

#####################################
# Part-Of-Speech adjective, verb, adverb, noun, name
#####################################

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory))

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory))


#####################################
# Part-Of-Speech adjective
#####################################

focus = "adjective"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech noun
#####################################

focus = "noun"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech verb
#####################################

focus = "verb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech adverb
#####################################

focus = "adverb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech name
#####################################

focus = "name"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
############ Wirtschaft #############
#####################################

# Analysis for Catagory "Politik"
# Grouped by Year and Month
catagory = "Wirtschaft"

#####################################
# Part-Of-Speech adjective, verb, adverb, noun, name
#####################################

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory))

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory))


#####################################
# Part-Of-Speech adjective
#####################################

focus = "adjective"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech noun
#####################################

focus = "noun"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech verb
#####################################

focus = "verb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech adverb
#####################################

focus = "adverb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech name
#####################################

focus = "name"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
############## Kultur ###############
#####################################

# Analysis for Catagory "Politik"
# Grouped by Year and Month
catagory = "Kultur"

#####################################
# Part-Of-Speech adjective, verb, adverb, noun, name
#####################################

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory))

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory))


#####################################
# Part-Of-Speech adjective
#####################################

focus = "adjective"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech noun
#####################################

focus = "noun"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech verb
#####################################

focus = "verb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech adverb
#####################################

focus = "adverb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech name
#####################################

focus = "name"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
############## Meinung ##############
#####################################

# Analysis for Catagory "Politik"
# Grouped by Year and Month
catagory = "Meinung"

#####################################
# Part-Of-Speech adjective, verb, adverb, noun, name
#####################################

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory))

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory))


#####################################
# Part-Of-Speech adjective
#####################################

focus = "adjective"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech noun
#####################################

focus = "noun"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech verb
#####################################

focus = "verb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech adverb
#####################################

focus = "adverb"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)

#####################################
# Part-Of-Speech name
#####################################

focus = "name"

##SPON
data.SPON.filtered <- filter(data.SPON, grepl(catagory, data.SPON$cats))
data.SPON.grouped = summarise(group_by(data.SPON.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.SPON.grouped, paste(paste("/share/Ergebnisse/Count/SPON/", catagory, "/", focus, "/"), catagory), focus)

##JF
data.JF.filtered <- filter(data.JF, grepl(catagory, data.JF$cats))
data.JF.grouped = summarise(group_by(data.JF.filtered, year, month), article = paste(article, sep = ' ', collapse = ' '), cats = paste(cats, sep = ' ', collapse = ' '))
analyse.all(data.JF.grouped, paste(paste("/share/Ergebnisse/Count/JF/", catagory, "/", focus, "/"), catagory), focus)
