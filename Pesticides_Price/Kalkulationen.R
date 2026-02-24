rm(list = ls())
cat("\014")

setwd("PATH")

library(openxlsx)
library(tidyverse)
library(writexl)
library(xml2)


#1. load data
pesticides_price <- read_excel("../Pesticides_Price/Kalkulationsdaten_Marktfrüchte.xlsx", sheet = "SDK5", range = "C4:D85")
bvl_primary <- read.csv("../Pesticide_Info/BVL_Primary.csv")

#2. remove NA rows
pesticides_price <- pesticides_price %>%
  filter(rowSums(is.na(.)) < ncol(pesticides_price))

#3. apply normalisation before merging
bvl_primary <- bvl_primary %>% 
  mutate(Normalised_Handelsbezeichnung  = case_when(
    str_detect(Handelsbezeichnung , fixed("Arrat")) ~ "Arrat + Dash",
    str_detect(Handelsbezeichnung , fixed("AGIL-S")) ~ "Agil-S",
    str_detect(Handelsbezeichnung , fixed("ARIANE C")) ~ "Ariane C",
    str_detect(Handelsbezeichnung , fixed("ARTUS")) ~ "Artus",
    str_detect(Handelsbezeichnung , fixed("Atlantis Flex")) ~ "Atlantis Flex + Biopower",
    str_detect(Handelsbezeichnung , fixed("AXIAL 50")) ~ "Axial 50",
    str_detect(Handelsbezeichnung , fixed("Betanal Tandem")) ~ "Betanal Tandem + Mero",
    str_detect(Handelsbezeichnung , fixed("Biathlon 4D")) ~ "Biathlon 4D +Dash",
    str_detect(Handelsbezeichnung , fixed("AMISTAR GOLD")) ~ "Amistar Gold",
    str_detect(Handelsbezeichnung , fixed("BROADWAY")) ~ "Broadway",
    str_detect(Handelsbezeichnung , fixed("Cantus")) ~ "Cantus Gold",
    str_detect(Handelsbezeichnung , fixed("Cantus Ultra")) ~ "Cantus Gold",
    str_detect(Handelsbezeichnung , fixed("SPARTA CCC 720")) ~ "CCC 720",
    str_detect(Handelsbezeichnung , fixed("STEFES CCC 720")) ~ "CCC 720",
    str_detect(Handelsbezeichnung , fixed("CORAGEN")) ~ "Coragen",
    str_detect(Handelsbezeichnung , fixed("EFFIGO")) ~ "Effigo",
    str_detect(Handelsbezeichnung , fixed("ELATUS ERA")) ~ "Elatus Era",
    str_detect(Handelsbezeichnung , fixed("Focus Ultra")) ~ "Focus Aktiv Pack, Focus Ultra",
    str_detect(Handelsbezeichnung , fixed("GOLTIX TITAN")) ~ "Goltix Titan",
    str_detect(Handelsbezeichnung , fixed("HARMONY SX")) ~ "Harmony SX",
    str_detect(Handelsbezeichnung , fixed("Mais-Banvel WG")) ~ "Mais Banvel WG",
    str_detect(Handelsbezeichnung , fixed("MaisTer power")) ~ "MaisTer Power",
    str_detect(Handelsbezeichnung , fixed("POINTER Plus")) ~ "Pointer Plus",
    str_detect(Handelsbezeichnung , fixed("REVUS")) ~ "Revus",
    str_detect(Handelsbezeichnung , fixed("Roundup PowerFlex")) ~ "Roundup Power Flex",
    str_detect(Handelsbezeichnung , fixed("Roundup REKORD")) ~ "Roundup Rekord",
    TRUE ~ Handelsbezeichnung
  ))

#4. join bvl_primary with pesticides price
bvl_primary <- bvl_primary %>%
  left_join(pesticides_price, by = c("Normalised_Handelsbezeichnung" = "Mittel")) %>% 
  rename(Preis = `Preis o.MwSt.`) %>% 
  select(Zulassungsnr, Handelsbezeichnung, Zulassungsende, Wirkungsbereich, Preis)

# #5. write output
write.csv(bvl_primary, "../Pesticides_Price/Pest_price_Kalkulations.csv", row.names = FALSE)
# write_xlsx(bvl_primary, "../Pesticides_Price/Pest_price_Kalkulations.xlsx")