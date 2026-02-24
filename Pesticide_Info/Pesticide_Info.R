rm(list = ls())
cat("\014")

setwd("PATH")

#1. load necessary libraries
library(data.table)
library(tidyverse)

#2. load the data
Pest_Info <- fread("Pesticide_Info.csv")

#3. primary table

#3.1 extract the relevant information
bvl_primary <- Pest_Info %>% 
  separate_rows(GHS, sep = "\n") %>% 
  filter(GHS != "") %>% 
  select(Zulassungsnr, Handelsbezeichnung, Zulassungsende, Wirkungsbereich, GHS)

#3.2 write output as csv
fwrite(bvl_primary, "BVL_Primary.csv")

#4. ingredient table

#4.1 build a sub table
bvl_ingred <- Pest_Info %>%
  
  # extract Zulassungsnr.and Wirkstoffgehalt
  select(Zulassungsnr, Wirkungsbereich, Wirkstoffgehalt) %>% 
  separate_rows(Wirkstoffgehalt, sep = "\n") %>% 

  # Handle 'Fettsäuren (C7 - C20)' specifically
  mutate(Wirkstoffgehalt = str_replace(Wirkstoffgehalt, "Fettsäuren\\s+\\(C7\\s+-\\s+C20\\) ",
                                        "Fettsäuren (C7 - C20) ")) %>% 
  
  # Condition to replace double space before the parenthesis with single space when "IU/mg" or "cfu/l" is detected
  mutate(Wirkstoffgehalt = ifelse(
    str_detect(Wirkstoffgehalt, "IU/mg|cfu/l"),
    str_replace_all(Wirkstoffgehalt, "\\s{2}", " "),
    Wirkstoffgehalt
  )) %>% 
  
  # Separate the column based on double spaces
  separate(Wirkstoffgehalt, into = c("Wirkstoffgehalt (Main)", "Wirkstoffgehalt (Compound)"), sep = "\\s{2}", fill = "right") %>% 
  
  # Extract Gehalt, Einhalt, and Wirkstoff from Wirkstoffgehalt (Main)
  extract(`Wirkstoffgehalt (Main)`, into = c("Gehalt_Main", "Einhalt_Main", "Wirkstoff_Main"),
          regex = "^(\\d+[,.]*\\d*)\\s([a-z/]+)\\s(.+)$",
          remove = FALSE) %>%
  
  # Remove parentheses in the Wirkstoffgehalt (Compound) column
  mutate(`Wirkstoffgehalt (Compound)` = str_replace_all(`Wirkstoffgehalt (Compound)`, "[()]", "")) %>% 
  
  # Extract Gehalt, Einhalt, and Wirkstoff from Wirkstoffgehalt (Compound)
  extract(`Wirkstoffgehalt (Compound)`, into = c("Gehalt_Compound", "Einhalt_Compound", "Wirkstoff_Compound"),
          regex = "^(\\d+[,.]*\\d*)\\s([a-z/]+)\\s(.+)$",
          remove = FALSE) %>%

  # Replace comma by decimal point, vice versa
  mutate(
    Gehalt_Main = gsub(",", "TEMP", Gehalt_Main),   # Replace commas with TEMP
    Gehalt_Main = gsub("\\.", ",", Gehalt_Main),    # Replace dots with commas
    Gehalt_Main = gsub("TEMP", ".", Gehalt_Main),    # Replace TEMP with dots
    Gehalt_Compound = gsub(",", "TEMP", Gehalt_Compound),
    Gehalt_Compound = gsub("\\.", ",", Gehalt_Compound),    
    Gehalt_Compound = gsub("TEMP", ".", Gehalt_Compound)    
  ) %>% 
  
  # Remove whitespace in the string
  mutate(Wirkstoff_Main = str_trim(Wirkstoff_Main),
         Wirkstoff_Compound = str_trim(Wirkstoff_Compound)) %>% 
    
  # Add dummy for bacteria  
  mutate(Organismus_Bakteria = as.integer(str_detect(`Wirkstoffgehalt (Main)`, "IU/mg|cfu/l|cfu/kg"))) %>% 
           
  # Arrange columns to match the new structure you described
  select(Zulassungsnr, Wirkungsbereich, Wirkstoff_Main, Gehalt_Main, Einhalt_Main, Wirkstoff_Compound, Gehalt_Compound, Einhalt_Compound, Organismus_Bakteria)

#4.2 write the output as csv
fwrite(bvl_ingred, "BVL_Ingredients.csv")

#5. additional information table

#5.1 parse the Hinweise
bvl_hin <- Pest_Info %>%
  mutate(Hinweise = str_replace_all(Hinweise, "\\r\\n", "\n")) %>%  # Normalize line breaks
  separate_rows(Hinweise, sep = "\n") %>%
  filter(Hinweise != "") %>%
  mutate(Code_Hinweis = str_extract(Hinweise, "^[A-Z0-9]+(?=:)")) %>%
  mutate(Text_Hinweis = str_replace(Hinweise, "^[A-Z0-9]+: ", "")) %>%
  select(Zulassungsnr, Code_Hinweis, Text_Hinweis)

#5.2 modify 'Code_Hinweis' if 'Text_Hinweis' is NA and keep all rows
bvl_hin <- bvl_hin %>%
  mutate(Code_Hinweis = if_else(is.na(Text_Hinweis) | Text_Hinweis == "N/A", "N/A", Code_Hinweis))

#5.3 write the output as csv
fwrite(bvl_hin, "BVL_Hinweise.csv")