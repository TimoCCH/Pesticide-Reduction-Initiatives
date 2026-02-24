rm(list = ls())
cat("\014")

setwd("PATH")

library(openxlsx)
library(tidyverse)
library(writexl)
library(xml2)


#1. read the data
avagrar <- read.csv("Avagrar.csv")

#2. convert HTML entities to normal characters
convert_html_entities <- function(text) {
  as.character(xml2::xml_text(xml2::read_html(paste0("<x>", text, "</x>"))))
}
colnames(avagrar) <- sapply(colnames(avagrar), convert_html_entities, USE.NAMES = FALSE)
avagrar$Handelsbezeichnung <- sapply(avagrar$Handelsbezeichnung, convert_html_entities)
avagrar$Grundpreis <- sapply(avagrar$Grundpreis, convert_html_entities)
avagrar$Gebindepreis <- sapply(avagrar$Gebindepreis, convert_html_entities)
avagrar$Gebinde <- sapply(avagrar$Gebinde, convert_html_entities)

#3. clean the dataframe

#3.1 remove parentheses, asterisks and convert decimal comma to dot
avagrar$Grundpreis <- gsub("[()*]", "", avagrar$Grundpreis)           # remove parentheses
avagrar$Grundpreis <- gsub("\\*", "", avagrar$Grundpreis)             # remove asterisks
avagrar$Grundpreis <- gsub(",", "TEMP", avagrar$Grundpreis)           # comma to TEMP
avagrar$Grundpreis <- gsub("\\.", ",", avagrar$Grundpreis)            # dot to comma
avagrar$Grundpreis <- gsub("TEMP", ".", avagrar$Grundpreis)           # TEMP to dot
avagrar$Grundpreis <- recode(avagrar$Grundpreis, "Gramm" = "g")
avagrar$Gebindepreis <- gsub("\\*", "", avagrar$Gebindepreis)             # remove asterisks
avagrar$Gebindepreis <- gsub(",", "TEMP", avagrar$Gebindepreis)           # comma to TEMP
avagrar$Gebindepreis <- gsub("\\.", ",", avagrar$Gebindepreis)            # dot to comma
avagrar$Gebindepreis <- gsub("TEMP", ".", avagrar$Gebindepreis)           # TEMP to dot

#3.2 transform the unit from uppercase to lowercase
avagrar$Gebinde <- gsub("Liter", "l", avagrar$Gebinde)
avagrar$Gebinde <- gsub("Kilogramm", "kg", avagrar$Gebinde)
avagrar$Grundpreis <- gsub("Liter", "l", avagrar$Grundpreis)
avagrar$Grundpreis <- gsub("Kilogramm", "kg", avagrar$Grundpreis)

#3.3 create the Gebindegröße  and the Gebindegröße_Einheit column
avagrar$Gebindegröße  <- ifelse(avagrar$Gebinde == "N/A", NA, str_extract(avagrar$Gebinde, "^[0-9.]+"))
avagrar$Gebindegröße_Einheit <- ifelse(
  avagrar$Gebinde == "N/A", 
  NA, 
  sub("^[0-9.]+\\s*", "", avagrar$Gebinde)
)
avagrar$Gebindegröße_Einheit <- recode(
  avagrar$Gebindegröße_Einheit,
  "Stück" = "St.",
  "Gramm" = "g"
)

#3.4 remove "1 " in Grundpreis (before unit)
avagrar$Grundpreis <- gsub("/ 1\\s*", "/ ", avagrar$Grundpreis)

#3.5  remove € symbol and whitespace
avagrar$Grundpreis <- gsub("€", "", avagrar$Grundpreis)
avagrar$Grundpreis <- gsub("\\s*/\\s*", "/", avagrar$Grundpreis)  # remove all spaces around slash
avagrar$Grundpreis <- gsub("\u00A0", "", avagrar$Grundpreis)
avagrar$Grundpreis <- trimws(avagrar$Grundpreis)
avagrar$Gebindepreis <- gsub("€", "", avagrar$Gebindepreis)
avagrar$Gebindepreis <- gsub("\\s*/\\s*", "/", avagrar$Gebindepreis)  # remove all spaces around slash
avagrar$Gebindepreis <- gsub("\u00A0", "", avagrar$Gebindepreis)
avagrar$Gebindepreis <- trimws(avagrar$Gebindepreis)

#3.6 create the Grundpreis_Einheit column
avagrar$Grundpreis_Einheit <- ifelse(avagrar$Grundpreis == "N/A", NA, str_extract(avagrar$Grundpreis, "(?<=/)[a-zA-Z.]+$"))
avagrar$Grundpreis <- str_extract(avagrar$Grundpreis, "^[0-9.,]+")

#3.6 re-arrange the column
avagrar <- avagrar %>% 
  select(Handelsbezeichnung, Grundpreis, Grundpreis_Einheit, Gebindepreis, Gebinde, Gebindegröße, Gebindegröße_Einheit)

#4. write output
write.csv(avagrar, "Pest_price_Avagrar.csv", row.names = FALSE)
# write_xlsx(avagrar, "Pest_price_Avagrar.xlsx")