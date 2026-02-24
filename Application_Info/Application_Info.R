rm(list = ls())
cat("\014")

setwd("PATH")

#1. load necessary libraries
library(data.table)
library(tidyverse)

#2. load the data
App_Info <- fread("Application_Info.csv")

#3. split 'Kultur/Objekt' into multiple rows
App_Info <- App_Info %>%
  
  # Replace commas inside parentheses
  mutate(`Kultur/Objekt` = str_replace_all(`Kultur/Objekt`, "\\(([^)]+)\\)", ~ gsub(",", "TEMP", .x))) %>%
  
  # Protect segments following semicolons or colons
  mutate(`Kultur/Objekt` = str_replace_all(`Kultur/Objekt`, "[:;].*", ~ gsub(",", "TEMP", .x))) %>%
  
  # Separate rows where commas are not protected
  separate_rows(`Kultur/Objekt`, sep = ", ") %>%
  
  # Replace the placeholders back to commas
  mutate(`Kultur/Objekt` = str_replace_all(`Kultur/Objekt`, "TEMP", ","))

#4. adjust the 'Anwendungszeitpunkt' column to remove leading commas or semicolons
App_Info <- App_Info %>%
  mutate(Anwendungszeitpunkt = str_replace(Anwendungszeitpunkt, "^[,;]\\s*", ""))

#5. split 'Max. Zahl Behandlungen' into three columns
App_Info <- App_Info %>%
  mutate(Max_Behandlungen_Anwendungen = str_extract(`Max. Zahl Behandlungen`, "(?<=In der Anwendung: )\\d+"),
         Max_Behandlungen_Jahr = str_extract(`Max. Zahl Behandlungen`, "(?<=In der Kultur bzw. je Jahr: )\\d+"),
         Abstand = str_extract(`Max. Zahl Behandlungen`, "(?<=Abstand: )[^\\n]+")) %>%
  mutate(across(c(Max_Behandlungen_Anwendungen, Max_Behandlungen_Jahr, Abstand), ~if_else(is.na(.), "N/A", .)))

#6. decompose 'Aufwand' into detailed components

#6.1 Split applications into separate rows
App_Info <- App_Info %>%
  
  # Step 1: Insert delimiters for 'Wasser' and 'kg/m³'
  mutate(
    Aufwand = str_replace_all(Aufwand, "Wasser", "Wasser||"),
    Aufwand = str_replace_all(Aufwand, "kg/m³", "kg/m³||")
  ) %>%
  
  # Step 2: Separate the rows on these delimiters
  separate_rows(Aufwand, sep = "\\|\\|") %>%
  
  # Step 3: Trim whitespace
  mutate(Aufwand = str_trim(Aufwand)) %>%
  
  # Step 4: Filter out empty rows and duplicate 'Wasser'
  filter(Aufwand != "", Aufwand != "Wasser") %>%
  
  # Step 5: Insert delimiters before digits leading "bis" for plant sizes
  mutate(Aufwand = str_replace_all(Aufwand, "(\\d+\\- bis)", "|||\\1")) %>%
  
  # Step 6: Expand entries into separate rows based on 'bis' delimiters
  separate_rows(Aufwand, sep = "\\|\\|\\|", convert = TRUE) %>%
  
  # Step 7: Remove any empty entries that may have resulted from separation
  filter(Aufwand != "") %>%
  
  # Step 8: Insert delimiters for 'Pflanzengröße', avoiding the start of the string
  mutate(Aufwand = str_replace_all(Aufwand, "(?<!^)(Pflanzengröße)", "|||\\1")) %>%
  
  # Step 9: Separate again based on the new 'Pflanzengröße' delimiters
  separate_rows(Aufwand, sep = "\\|\\|\\|")

#6.2 define patterns

#6.2.1 regular patterns
Reg_pattern <- "(\\d+[,.]?\\d*)\\s*(ml|l|ml/ha|l/ha|g/ha|kg/ha|ml/dt|l/dt|l/t|ml/100 m²|l/100 m²|g je 100 m²|g/1000 Pflanzen|ml/1000 Pflanzen|l/100 kg Substrat|l/10.000 m² Laubwandfläche|kg/10.000 m² Laubwandfläche)\\s*in\\s*(\\d+[,.]?\\d*)\\s*bis\\s*(\\d+[,.]?\\d*)\\s*(l|ml/ha|l/ha|g/ha|kg/ha|ml/dt|l/dt|l/t|ml/100 m²|l/m²|l/100 m²|l pro 1000 Pflanzen|l/100 kg Substrat|l/10.000 m² Laubwandfläche)\\s+Wasser"

#6.2.2 with mindestens
Min_pattern <- "(\\d+[,.]?\\d*)\\s*(l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|l/t|ml/kg|ml/100 m²|l/100 m²|g je 100 m²|g/1000 Pflanzen|ml/100 m² und je m Kronenhöhe|g/100 m² und je m Kronenhöhe)\\s*in\\s*mindestens\\s*(\\d+[,.]?\\d*)\\s*(l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|l/t|ml/kg|l/100 m²|l pro 1000 Pflanzen|l/100 m² und je m Kronenhöhe)\\s+Wasser"

#6.2.3 with maximal
Max_pattern <- "(\\d+[,.]?\\d*)\\s*(l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|l/t|ml/kg|ml/100 m²|l/100 m²|g je 100 m²|g/1000 Pflanzen|ml/100 m² und je m Kronenhöhe)\\s*in\\s*maximal\\s*(\\d+[,.]?\\d*)\\s*(l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|l/t|ml/kg|l/100 m²|l pro 1000 Pflanzen|l/100 m² und je m Kronenhöhe)\\s+Wasser"

#6.2.4 min and max the same
MinMax_pattern <- "(\\d+[,.]?\\d*)\\s*(l|l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|l/t|g|kg|ml/10 m²|ml/100 m²|l/100 m²|g je 100 m²|g je 100 m³|ml/1000 Pflanzen|g/100 kg Substrat|ml je l Substrat|ml/100 m² und je m Kronenhöhe|ml/100 m² und je m Kronenehöhe bei maximal 2 m Kronenhöhe)\\s*in\\s*(\\d+[,.]?\\d*)\\s*(l|l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|l/t|l/m²|ml/10 m²|l/10 m²|l/100 m²|l/100 kg Substrat|ml je l Substrat|l/100 m² und je m Kronenhöhe|ml/100 m² und je m Kronenhöhe|l/100 m² und je m Kronenhöhe bei maximal 2 m Kronenhöhe)\\s+Wasser"

#6.2.5 without min and max
NoMinMax_pattern <- 
  "(\\d+[,.]?\\d*)\\s*(l/ha|ml/ha|g/ha|kg/ha|l/dt|ml/dt|ml/l|g/l|ml/t|l/t|g/t|kg/t|l/ 100 t|g/kg|%|g/m²|g h/m³|ml/m²|ml/100 m²|ml/m³|l/m³|mg/m³|ml je 100 m³|g je 100 m²|g je 100 m³|g/m³|g je 6 m³|kg/m³|g pro Gang|g pro Bau|ml pro Einheit Saatgut|l pro 1000 Pflanzen|kg pro 1000 Pflanzen|Dispenser je ha|Dose\\(n\\) je 1000 m³|Stück je t|Stück je m³|Körner pro Pflanzrohr|ml/100.000 Korn Saatgut|ml je 100 l Prozesswasser|g je 8-10 m Ganglänge|Stück je 3-5 m Ganglänge|ml/1000 Korn|ml pro kg Saatgut|ml pro 100 kg Saatgut|g pro Pflanze|g pro Stamm|ml pro Stamm|Stück pro Loch|Ampulle\\(n\\) je ha|g pro Köderstelle|Stück pro Köderstelle|g pro Einheit Saatgut|Tablette\\(n\\) je l|ml je 10 cm Stammumfang|g/ 100 m Begrünungsstreifen und je 1 m Streifenbreite|Stäbchen pro Topf)"

#6.3 apply patterns and manage differing column structures
App_Info <- App_Info %>%
  mutate(
    Match_reg = str_match(Aufwand, Reg_pattern),
    Match_min = str_match(Aufwand, Min_pattern),
    Match_max = str_match(Aufwand, Max_pattern),
    Match_minmax = str_match(Aufwand, MinMax_pattern),
    Match_nominmax = str_match(Aufwand, NoMinMax_pattern),
    
    Aufwandmenge = coalesce(Match_reg[, 2], 
                            Match_min[, 2],
                            Match_max[, 2],
                            Match_minmax[, 2],
                            Match_nominmax[, 2]),
    
    Aufwandmenge_Einheit = coalesce(Match_reg[, 3], 
                                    Match_min[, 3], 
                                    Match_max[, 3],
                                    Match_minmax[, 3],
                                    Match_nominmax[, 3]),
    
    Verduennung_Menge_Min = coalesce(Match_reg[, 4], 
                                     Match_min[, 4], 
                                     Match_minmax[, 4]),
    
    Verduennung_Menge_Max = coalesce(Match_reg[, 5],
                                     Match_max[, 4],
                                     Match_minmax[, 4]),
    
    Verduennung_Einheit = coalesce(Match_reg[, 6], 
                                   Match_min[, 5], 
                                   Match_max[ ,5],
                                   Match_minmax[, 5]),
    
    Verduennungsmittel = coalesce(str_extract(Match_reg[, 1], "\\bWasser\\b$"), 
                                  str_extract(Match_min[, 1], "\\bWasser\\b$"),
                                  str_extract(Match_max[, 1], "\\bWasser\\b$"),
                                  str_extract(Match_minmax[, 1], "\\bWasser\\b$"))
  ) %>%
  select(-c(Match_reg, Match_min, Match_max, Match_minmax, Match_nominmax))

#6.4 replace comma by decimal point, vice versa
App_Info <- App_Info %>%
  mutate(
    Aufwandmenge = gsub(",", "TEMP", Aufwandmenge, fixed = TRUE), # Replace commas with TEMP
    Aufwandmenge = gsub("\\.", ",", Aufwandmenge, fixed = FALSE), # Replace dots with commas
    Aufwandmenge = gsub("TEMP", ".", Aufwandmenge, fixed = TRUE), # Replace TEMP with dots
    
    Verduennung_Menge_Min = gsub(",", "TEMP", Verduennung_Menge_Min, fixed = TRUE),
    Verduennung_Menge_Min = gsub("\\.", ",", Verduennung_Menge_Min, fixed = FALSE),
    Verduennung_Menge_Min = gsub("TEMP", ".", Verduennung_Menge_Min, fixed = TRUE),
    
    Verduennung_Menge_Max = gsub(",", "TEMP", Verduennung_Menge_Max, fixed = TRUE),
    Verduennung_Menge_Max = gsub("\\.", ",", Verduennung_Menge_Max, fixed = FALSE),
    Verduennung_Menge_Max = gsub("TEMP", ".", Verduennung_Menge_Max, fixed = TRUE)
  )

#7. define crop fields or grassland
App_Info <- App_Info %>%
  mutate(`Ackerbau/Grünland` = if_else(str_detect(Einsatzgebiet, "Ackerbau|Grünland"), 1, 0))

#8. define post harvest or sprouting
App_Info <- App_Info %>% 
  mutate(`Austrieb/Ernte` = if_else(str_detect(Aufwand, "nach der Ernte|nach Austrieb"), 1, 0))

#9. write output to csv file
App_Info <- App_Info %>% rename(Zulassungsnr = Zulassungsnr.)
fwrite(App_Info, "BVL_Applications.csv")

# # List unique values from 'Aufwandmenge_Einheit'
# print(sort(unique(App_Info$Aufwandmenge_Einheit)))
# 
# # List unique values from 'Verduennung_Einheit'
# print(sort(unique(App_Info$Verduennung_Einheit)))

# # Filter rows where 'Ackerbau/Grünland' == 1 and get unique values from 'Aufwandmenge_Einheit'
# unique_values <- App_Info %>%
#   filter(`Ackerbau/Grünland` == 1) %>%
#   pull(Aufwandmenge_Einheit) %>%
#   unique()