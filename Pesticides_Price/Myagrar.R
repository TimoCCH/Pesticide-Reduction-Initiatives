rm(list = ls())
cat("\014")

setwd("PATH")

library(openxlsx)
library(tidyverse)
library(writexl)
library(xml2)


#1. read the data
myagrar <- read.csv("myagrar.csv")

#2. convert HTML entities to normal characters
convert_html_entities <- function(text) {
  as.character(xml2::xml_text(xml2::read_html(paste0("<x>", text, "</x>"))))
}
colnames(myagrar) <- sapply(colnames(myagrar), convert_html_entities, USE.NAMES = FALSE)
myagrar$Handelsbezeichnung <- sapply(myagrar$Handelsbezeichnung, convert_html_entities)
myagrar$Grundpreis <- sapply(myagrar$Grundpreis, convert_html_entities)
myagrar$Gebindepreis <- sapply(myagrar$Gebindepreis, convert_html_entities)

#3. clean the dataframe

#3.1 remove € symbol and whitespace
myagrar$Grundpreis <- gsub("€", "", myagrar$Grundpreis)
myagrar$Grundpreis <- gsub("\\s*/\\s*", "/", myagrar$Grundpreis)  # remove all spaces around slash
myagrar$Grundpreis <- gsub("\u00A0", "", myagrar$Grundpreis)
myagrar$Grundpreis <- trimws(myagrar$Grundpreis)

#3.2 convert decimal comma to dot
myagrar$Grundpreis <- gsub(",", "TEMP", myagrar$Grundpreis)           # comma to TEMP
myagrar$Grundpreis <- gsub("\\.", ",", myagrar$Grundpreis)            # dot to comma
myagrar$Grundpreis <- gsub("TEMP", ".", myagrar$Grundpreis)           # TEMP to dot
myagrar$Gebindepreis <- gsub(",", "TEMP", myagrar$Gebindepreis)           # comma to TEMP
myagrar$Gebindepreis <- gsub("\\.", ",", myagrar$Gebindepreis)            # dot to comma
myagrar$Gebindepreis <- gsub("TEMP", ".", myagrar$Gebindepreis)           # TEMP to dot

#3.3 create the Gebinde_Einheit column
myagrar$Grundpreis_Einheit <- case_when(
  myagrar$Grundpreis == "N/A" ~ NA_character_,
  myagrar$Grundpreis == "Preis auf Anfrage" ~ "Preis auf Anfrage",
  str_detect(myagrar$Grundpreis, "^[0-9.,]+\\s*/\\s*[a-zA-Z.]+$") ~ 
    str_trim(str_extract(myagrar$Grundpreis, "(?<=/)\\s*[a-zA-Z.]+$")),
  TRUE ~ NA_character_
)

#3.4 keep only the number in Grundpreis
myagrar$Grundpreis <- case_when(
  myagrar$Grundpreis == "N/A" ~ NA_character_,
  myagrar$Grundpreis == "Preis auf Anfrage" ~ "Preis auf Anfrage",
  str_detect(myagrar$Grundpreis, "^[0-9.,]+\\s*/\\s*[a-zA-Z.]+$") ~ 
    str_extract(myagrar$Grundpreis, "^[0-9.,]+"),
  TRUE ~ myagrar$Grundpreis
)

#3.5 create the Gebindepreis_Einheit column
myagrar <- myagrar %>%
  mutate(
    Gebinde  = str_trim(str_remove(str_extract(Gebindepreis, "(?<=€).*"), "^\\s*pro\\s*")),
    num_unit = str_extract(Gebinde, "\\d+\\s*[[:alpha:]]+"),
    Gebindegröße_Einheit = str_extract(num_unit, "[[:alpha:]]+"),
    Gebindegröße = str_trim(str_extract(Gebinde, "^[0-9.,]+")),
    Gebindepreis = str_trim(str_extract(Gebindepreis, "^[0-9.,]+"))
  ) %>%
  select(-num_unit)
myagrar$Gebindegröße  <- gsub(",", ".", myagrar$Gebindegröße)
myagrar$Gebinde  <- gsub(",", ".", myagrar$Gebinde)

#3.6 re-arrange the column
myagrar <- myagrar %>% select(
  Handelsbezeichnung, Grundpreis, Grundpreis_Einheit, Gebindepreis, Gebinde, Gebindegröße, Gebindegröße_Einheit
)

#4. write output
write.csv(myagrar, "Pest_price_Myagrar.csv", row.names = FALSE)
# write_xlsx(myagrar, "Pest_price_Myagrar.xlsx")
