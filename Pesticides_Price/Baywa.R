rm(list = ls())
cat("\014")

setwd("PATH")

library(openxlsx)
library(tidyverse)
library(writexl)
library(xml2)


#1. read the data
baywa <- read.csv("Baywa.csv")

#2. convert HTML entities to normal characters
convert_html_entities <- function(text) {
  as.character(xml2::xml_text(xml2::read_html(paste0("<x>", text, "</x>"))))
}
colnames(baywa) <- sapply(colnames(baywa), convert_html_entities, USE.NAMES = FALSE)
baywa$Handelsbezeichnung <- sapply(baywa$Handelsbezeichnung, convert_html_entities)
baywa$Grundpreis <- sapply(baywa$Grundpreis, convert_html_entities)
baywa$Gebinde_info <- sapply(baywa$Gebinde_info, convert_html_entities)

#3. clean the dataframe

#3.1 remove "Grundpreis:", newline characters and convert decimal comma to dot
baywa$Grundpreis <- gsub("Grundpreis:\\s*", "", baywa$Grundpreis)  # Remove label
baywa$Grundpreis <- gsub("\\s*\\n\\s*", "", baywa$Grundpreis)      # Remove newlines and surrounding space
baywa$Grundpreis <- gsub("\u00A0", "", baywa$Grundpreis)           # Remove non-breaking space (HTML space)
baywa$Grundpreis <- gsub(",", "TEMP", baywa$Grundpreis)            # comma to TEMP
baywa$Grundpreis <- gsub("\\.", ",", baywa$Grundpreis)             # dot to comma
baywa$Grundpreis <- gsub("TEMP", ".", baywa$Grundpreis)            # TEMP to dot
baywa$Gebinde_info <- gsub("\\s*\\n\\s*", " ", baywa$Gebinde_info)
baywa$Gebinde_info <- gsub("\u00A0", "", baywa$Gebinde_info)
baywa$Gebinde_info <- gsub(",", "TEMP", baywa$Gebinde_info)
baywa$Gebinde_info <- gsub("\\.", ",", baywa$Gebinde_info)
baywa$Gebinde_info <- gsub("TEMP", ".", baywa$Gebinde_info)
baywa$Gebinde <- gsub(",", ".", baywa$Gebinde)

#3.3 create the Gebindegröße and the Gebindegröße_Einheit column
baywa$Gebindegröße <- ifelse(baywa$Gebinde == "N/A", NA, str_extract(baywa$Gebinde, "^[0-9.]+"))
baywa$Gebindegröße_Einheit <- ifelse(
  baywa$Gebinde == "N/A", 
  NA, 
  sub("^[0-9.]+\\s*", "", baywa$Gebinde)
)

#3.4 create the Grundpreis_Einheit column
baywa$Grundpreis_Einheit <- ifelse(baywa$Grundpreis == "N/A", NA, str_extract(baywa$Grundpreis, "(?<=/)[a-zA-Z.]+$"))
baywa$Grundpreis <- str_extract(baywa$Grundpreis, "^[0-9.,]+")

#3.5 transform the unit from uppercase to lowercase
baywa$Grundpreis <- gsub("KG", "kg", baywa$Grundpreis)
baywa$Grundpreis <- gsub("L", "l", baywa$Grundpreis)
baywa$Grundpreis_Einheit <- gsub("KG", "kg", baywa$Grundpreis_Einheit)
baywa$Grundpreis_Einheit <- gsub("L", "l", baywa$Grundpreis_Einheit)

#3.6 remove € symbol and whitespace
baywa$Grundpreis <- gsub("€", "", baywa$Grundpreis)
baywa$Gebinde_info <- gsub("€", "", baywa$Gebinde_info)
baywa$Gebinde_info <- gsub("\\s*/\\s*", "/", baywa$Gebinde_info)  # remove all spaces around slash

#3.7 create the Gebinde_info column
baywa <- baywa %>%
  mutate(
    Gebindepreis = if_else(
      str_detect(Gebinde_info, "^[0-9,.]+\\s*/\\s*[[:alpha:]]+"),
      str_extract(Gebinde_info, "^[0-9,.]+"),
      NA_character_
    )
  )

#3.8 re-arrange the column
baywa <- baywa %>% 
  select(Handelsbezeichnung, Grundpreis, Grundpreis_Einheit, Gebinde_info, Gebindepreis, Gebinde, Gebindegröße, Gebindegröße_Einheit)

#4. write output
write.csv(baywa, "Pest_price_Baywa.csv", row.names = FALSE)
# write_xlsx(baywa, "Pest_price_Baywa.xlsx")