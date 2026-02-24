rm(list = ls())
cat("\014")

setwd("PATH")

library(PesticideLoadIndicator)
library(openxlsx)
library(tidyverse)
library(writexl)


#Task 1 Create the list for scraping############################################

# Users could replace the ingred_list with their list if they have one. 
# They can create the list for scraping by following steps 1.1 and 1.2. 
# After that, they can scrape the data from the PPDB database using the PPDB_Ingred.py. 
# 
# Next, users can check the Unmatched_Pesticides (step 1.3) to identify which pesticide names need to be normalised (step 1.4). 
# Subsequently, they can update the ingred_list (step 1.5) and re-scrape the database. 
# Repeat the process (python scraping and step 1.3 to 1.5) until there are no unmatched pesticides remaining due to spelling differences.

#1.1 load the data
ingred_list <- read.csv("Pesticide_Info/BVL_Ingredients.csv") %>% 
  select(Wirkstoff_Main) %>% 
  mutate(Normalized_Wirkstoff = Wirkstoff_Main) %>% 
  distinct() 

#1.2 write csv
write.csv(ingred_list, "PPDB/Ingred_list.csv")

#1.3 read the list of unmatched substances
Unmatched_Pesticides <- read.csv("PPDB/Unmatched_Pesticides.csv")

#1.4 apply normalization
ingred_list <- ingred_list %>% 
  mutate(Normalized_Wirkstoff = case_when(
    # FRAC
    str_detect(Wirkstoff_Main, fixed("Prothioconazol")) ~ "Prothioconazole",
    str_detect(Wirkstoff_Main, fixed("Schwefel")) ~ "Sulphur",
    str_detect(Wirkstoff_Main, fixed("Bromuconazol")) ~ "Bromuconazole",
    str_detect(Wirkstoff_Main, fixed("Kaliumphosphonat (Kaliumphosphit)")) ~ "Potassium phosphonates",
    str_detect(Wirkstoff_Main, fixed("Metconazol")) ~ "Metconazole",
    str_detect(Wirkstoff_Main, fixed("Difenoconazol")) ~ "Difenoconazole",
    str_detect(Wirkstoff_Main, fixed("Bacillus amyloliquefaciens subsp. plantarum Stamm D747 50.000.000.000.000cfu/kg")) ~ "Bacillus amyloliquefaciens subsp. plantarum D747",
    str_detect(Wirkstoff_Main, fixed("Tebuconazol")) ~ "Tebuconazole",
    str_detect(Wirkstoff_Main, fixed("Kaliumhydrogencarbonat")) ~ "Potassium bicarbonate",
    str_detect(Wirkstoff_Main, fixed("Kupferoxychlorid")) ~ "Copper oxychloride",
    str_detect(Wirkstoff_Main, fixed("Kupferhydroxid")) ~ "Copper (II) hydroxide",
    str_detect(Wirkstoff_Main, fixed("Trichoderma gamsii Stamm ICC 080 (vormals T. viride) 15.000.000.000cfu/kg")) ~ "Trichoderma gamsii strain ICC080",
    str_detect(Wirkstoff_Main, fixed("Trichoderma asperellum Stamm ICC 012 (vormals T. harzianum) 15.000.000.000cfu/kg")) ~ "Trichoderma asperellum strain ICC012",
    str_detect(Wirkstoff_Main, fixed("Pseudomonas chlororaphis Stamm MA 342 2.200.000.000.000cfu/l")) ~ "Pseudomonas chlororaphis strain MA342",
    str_detect(Wirkstoff_Main, fixed("Thiabendazol")) ~ "Thiabendazole",
    str_detect(Wirkstoff_Main, fixed("Pseudomonas chlororaphis Stamm MA 342 4.000.000.000.000cfu/l")) ~ "Pseudomonas chlororaphis strain MA342",
    str_detect(Wirkstoff_Main, fixed("Kupfersulfat, dreibasisch")) ~ "Copper sulphate",
    str_detect(Wirkstoff_Main, fixed("Schwefelkalkbrühe")) ~ "Lime sulphur",
    str_detect(Wirkstoff_Main, fixed("Dodin")) ~ "Dodine",
    str_detect(Wirkstoff_Main, fixed("Verticillium albo-atrum Stamm WCS850 10.000.000.000cfu/l")) ~ "Verticillium albo-atrum",
    str_detect(Wirkstoff_Main, fixed("Bacillus amyloliquefaciens Stamm QST 713 (vormals B. subtilis) 1.000.000.000.000cfu/kg")) ~ "Bacillus amyloliquefaciens QST 713",
    str_detect(Wirkstoff_Main, fixed("Dinatriumphosphonat")) ~ "Disodium phosphonate",
    str_detect(Wirkstoff_Main, fixed("Bupirimat")) ~ "Bupirimate",
    str_detect(Wirkstoff_Main, fixed("Clonostachys rosea Stamm J1446 (vormals Gliocladium catenulatum) 100.000.000.000cfu/kg")) ~ "Clonostachys rosea strain J1446",
    str_detect(Wirkstoff_Main, fixed("Pseudomonas sp. Stamm DSMZ 13134 66.000.000.000.000cfu/kg")) ~ "Pseudomonas sp. strain DSMZ 13134",
    str_detect(Wirkstoff_Main, fixed("Trichoderma asperellum Stamm T34 1.000.000.000.000cfu/kg")) ~ "Trichoderma asperellum strain T34",
    str_detect(Wirkstoff_Main, fixed("Triticonazol")) ~ "Triticonazole",
    str_detect(Wirkstoff_Main, fixed("Bacillus amyloliquefaciens Stamm MBI 600 55.000.000.000.000cfu/kg")) ~ "Bacillus amyloliquefaciens MBI600",
    str_detect(Wirkstoff_Main, fixed("Penconazol")) ~ "Penconazole",
    str_detect(Wirkstoff_Main, fixed("Trichoderma atroviride Stamm I-1237 100.000.000.000cfu/kg")) ~ "Trichoderma atroviride strain I-1237",
    str_detect(Wirkstoff_Main, fixed("Trichoderma asperellum Stamm T34 10.000.000.000cfu/kg")) ~ "Trichoderma asperellum strain T34",
    str_detect(Wirkstoff_Main, fixed("8-Hydroxychinolin")) ~ "8-hydroxyquinoline",
    str_detect(Wirkstoff_Main, fixed("Bacillus amyloliquefaciens Stamm MBI 600 22.000.000.000.000cfu/l")) ~ "Bacillus amyloliquefaciens MBI600",
    str_detect(Wirkstoff_Main, fixed("2,5-Dichlorbenzoesäuremethylester")) ~ "2,5-dichlorobenzoic acid methyl ester",
    str_detect(Wirkstoff_Main, fixed("Copper (II) hydroxide")) ~ "Copper II hydroxide",
    
    #HRAC
    str_detect(Wirkstoff_Main, fixed("Quizalofop-P")) ~ "Quizalofop-P-ethyl",
    str_detect(Wirkstoff_Main, fixed("Glyphosat")) ~ "Glyphosate",
    str_detect(Wirkstoff_Main, fixed("Eisen-II-sulfat")) ~ "Iron sulphate",
    str_detect(Wirkstoff_Main, fixed("Napropamid")) ~ "Napropamide",
    str_detect(Wirkstoff_Main, fixed("Terbuthylazin")) ~ "Terbuthylazine",
    str_detect(Wirkstoff_Main, fixed("Propyzamid")) ~ "Propyzamide",
    str_detect(Wirkstoff_Main, fixed("Cloquintocet")) ~ "Cloquintocet-methyl",
    str_detect(Wirkstoff_Main, fixed("Fettsäuren (C7 - C20)")) ~ "Fatty acids (generic)",
    str_detect(Wirkstoff_Main, fixed("Ethofumesat")) ~ "Ethofumesate",
    str_detect(Wirkstoff_Main, fixed("Pelargonsäure")) ~ "Pelargonic acid",
    str_detect(Wirkstoff_Main, fixed("Pyridat")) ~ "Pyridate",
    str_detect(Wirkstoff_Main, fixed("Essigsäure")) ~ "Acetic acid",
    str_detect(Wirkstoff_Main, fixed("Maleinsäurehydrazid")) ~ "Maleic hydrazide",
    str_detect(Wirkstoff_Main, fixed("S-Metolachlor")) ~ "S-metolachlor",
    str_detect(Wirkstoff_Main, fixed("Pyraflufen")) ~ "Pyraflufen-ethyl",
    str_detect(Wirkstoff_Main, fixed("Sulcotrion")) ~ "Sulcotrione",
    
    #IRAC
    str_detect(Wirkstoff_Main, fixed("lambda-Cyhalothrin")) ~ "Lambda-cyhalothrin",
    str_detect(Wirkstoff_Main, fixed("Piperonylbutoxid")) ~ "Piperonyl butoxide",
    str_detect(Wirkstoff_Main, fixed("Orangenöl")) ~ "Orange oil",
    str_detect(Wirkstoff_Main, fixed("gamma-Cyhalothrin")) ~ "Gamma-cyhalothrin",
    str_detect(Wirkstoff_Main, fixed("Magnesiumphosphid")) ~ "Magnesium phosphide",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subspecies kurstaki Stamm ABTS-351 (Stamm HD-1) (33,2 g/l Grundkörper) 17.600IU/mg")) ~ "Bacillus thuringiensis subsp. kurstaki strain ABTS 351",
    str_detect(Wirkstoff_Main, fixed("tau-Fluvalinat")) ~ "Tau-fluvalinate",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subspecies aizawai Stamm ABTS-1857 (540 g/kg Grundkörper) 15.000IU/mg")) ~ "Bacillus thuringiensis subsp. aizawai strain ABTS-1857",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subspecies kurstaki Stamm ABTS-351 (Stamm HD-1) 16.700IU/mg")) ~ "Bacillus thuringiensis subsp. kurstaki strain ABTS 351",
    str_detect(Wirkstoff_Main, fixed("Phosphan (Phosphorwasserstoff)")) ~ "Phosphane",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subsp. israelensis (Serotyp H-14) AM65-52 5.600.000.000.000cfu/l")) ~ "Bacillus thuringiensis subsp. israelensis strain AM65-52",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subspecies kurstaki Stamm EG-2348 32.000IU/mg")) ~ "Bacillus thuringiensis subsp. kurstaki strain EG2348",
    str_detect(Wirkstoff_Main, fixed("Tebufenozid")) ~ "Tebufenozide",
    str_detect(Wirkstoff_Main, fixed("Sulfurylfluorid")) ~ "Sulfuryl fluoride",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subspecies aizawai Stamm GC-91 25.000IU/mg")) ~ "Bacillus thuringiensis subsp. aizawai strain GC-91",
    str_detect(Wirkstoff_Main, fixed("Paraffinöl (CAS 8042-47-5)")) ~ "Paraffin oil (CAS No: 8042-47-5)",
    str_detect(Wirkstoff_Main, fixed("Rapsöl")) ~ "rapeseed oil",
    str_detect(Wirkstoff_Main, fixed("Kohlendioxid")) ~ "Carbon dioxide",
    str_detect(Wirkstoff_Main, fixed("Grüne-Minze-?l")) ~ "Spearmint oil",
    str_detect(Wirkstoff_Main, fixed("Bacillus thuringiensis subspecies kurstaki Stamm ABTS-351 (Stamm HD-1) 11.700.000.000.000cfu/kg")) ~ "Bacillus thuringiensis subsp. kurstaki strain ABTS 351",
    str_detect(Wirkstoff_Main, fixed("Fenpyroximat")) ~ "Fenpyroximate",
    str_detect(Wirkstoff_Main, fixed("Benzoesäure")) ~ "Benzoic acid",
    str_detect(Wirkstoff_Main, fixed("Beauveria bassiana Stamm ATCC 74040 23.000.000.000cfu/l")) ~ "Beauveria bassiana strain ATCC 74040",
    str_detect(Wirkstoff_Main, fixed("Esfenvalerat")) ~ "Esfenvalerate",
    str_detect(Wirkstoff_Main, fixed("Formetanat")) ~ "Formetanate",
    str_detect(Wirkstoff_Main, fixed("rapeseed oil")) ~ "Rapeseed oil",
    str_detect(Wirkstoff_Main, fixed("Grüne-Minze-Öl")) ~ "Spearmint oil",
    str_detect(Wirkstoff_Main, fixed("Aluminiumphosphid")) ~ "Aluminium phosphide",
    str_detect(Wirkstoff_Main, fixed("Fatty acids (generic)")) ~ "Fatty acids (generic C7-C18)",
    str_detect(Wirkstoff_Main, fixed("Fatty acids unsaturated potassium salts (generic)")) ~ "Fatty acids unsaturated potassium salts (generic C7-C18)",
    
    #Others
    str_detect(Wirkstoff_Main, fixed("Trinexapac")) ~ "Trinexapac-ethyl",
    str_detect(Wirkstoff_Main, fixed("1-Decanol")) ~ "1-decanol",
    str_detect(Wirkstoff_Main, fixed("1-Methylcyclopropen")) ~ "1-methylcyclopropene",
    str_detect(Wirkstoff_Main, fixed("Prohexadion")) ~ "Prohexadione",
    str_detect(Wirkstoff_Main, fixed("Metaldehyd")) ~ "Metaldehyde",
    str_detect(Wirkstoff_Main, fixed("Zinkphosphid")) ~ "Zinc phosphide",
    str_detect(Wirkstoff_Main, fixed("Calciumcarbid")) ~ "Calcium carbide",
    str_detect(Wirkstoff_Main, fixed("Natrium-o-nitrophenolat")) ~ "Sodium o-nitrophenolate",
    str_detect(Wirkstoff_Main, fixed("Natrium-5-nitroguaiacolat")) ~ "Sodium 5-nitroguaiacolate",
    str_detect(Wirkstoff_Main, fixed("Natrium-p-nitrophenolat")) ~ "Sodium p-nitrophenolate",
    str_detect(Wirkstoff_Main, fixed("Blutmehl")) ~ "Blood meal",
    str_detect(Wirkstoff_Main, fixed("Fettsäure-Kaliumsalze (Kali-Seife)")) ~ "Fatty acids unsaturated potassium salts (generic)",
    str_detect(Wirkstoff_Main, fixed("1-Naphthylessigsäure")) ~ "1-naphthylacetic acid",
    str_detect(Wirkstoff_Main, fixed("Quarzsand")) ~ "Quartz sand",
    str_detect(Wirkstoff_Main, fixed("Daminozid")) ~ "Daminozide",
    str_detect(Wirkstoff_Main, fixed("1,4-Dimethylnaphthalin")) ~ "1,4-dimethylnaphthalene",
    str_detect(Wirkstoff_Main, fixed("Gibberelline (GA4/GA7)")) ~ "Gibberellins",
    str_detect(Wirkstoff_Main, fixed("Bacillus amyloliquefaciens subsp. plantarum Stamm D747 7.500.000.000.000cfu/l")) ~ "Bacillus amyloliquefaciens subsp. plantarum D747",
    str_detect(Wirkstoff_Main, fixed("Trichoderma atroviride Stamm AT10 100.000.000.000cfu/kg")) ~ "Trichoderma atroviride strain AT10",
    str_detect(Wirkstoff_Main, fixed("Clonostachys rosea Stamm J1446 (vormals Gliocladium catenulatum) 1.000.000.000.000cfu/kg")) ~ "Clonostachys rosea strain J1446",
    str_detect(Wirkstoff_Main, fixed("Eisen-III-phosphat")) ~ "Ferric phosphate",
    str_detect(Wirkstoff_Main, fixed("Eisen-III-pyrophosphat")) ~ "Ferric pyrophosphate",
    TRUE ~ Wirkstoff_Main
  ))

#1.5 write csv
write.csv(ingred_list, "PPDB/Ingred_list.csv")


#Task 2 Clean the scraping output###############################################

#2.1 load the data for ingredients
bvl_primary <- read.csv("Pesticide_Info/BVL_Primary.csv")
bvl_ingred <- read.csv("Pesticide_Info/BVL_Ingredients.csv")
PPDB_Ingred <- read.csv("PPDB/PPDB_Ingred.csv")
GHS_code <- read.csv("PPDB/GHS_code.csv", fileEncoding = "UTF-8")

#2.2 clean the GHS column for merging data
bvl_primary <- bvl_primary %>%
  mutate(GHS_clean = GHS %>%
           str_replace_all("[\\(\\)<>]", "") %>%
           str_squish())

GHS_code <- GHS_code %>%
  mutate(Wortlaut_clean = Wortlaut %>%
           str_replace_all("[\\(\\)<>]", "") %>%
           str_squish())

#2.3 join bvl_primary with GHS_code 
bvl_primary <- bvl_primary %>%
  left_join(GHS_code, by = c("GHS_clean" = "Wortlaut_clean")) %>% 
  group_by(Zulassungsnr, Handelsbezeichnung) %>%
  summarize(
    Code = paste(na.omit(Code), collapse = ","),
    .groups = "drop") %>% 
  mutate(Code = na_if(Code, ""))

#2.4 join different data
PPDB_Ingred <- ingred_list %>%
  left_join(PPDB_Ingred, by = c("Normalized_Wirkstoff" = "substance")) %>%
  left_join(bvl_ingred, by = "Wirkstoff_Main") %>% 
  left_join(bvl_primary, by = "Zulassungsnr")

#2.5 filter out the bacteria
PPDB_Ingred <- PPDB_Ingred %>%
  filter(Organismus_Bakteria == 0)

#2.6 clean the SCI.Grow column
PPDB_Ingred <- PPDB_Ingred %>%
  mutate(SCI.Grow = str_replace_all(SCI.Grow, "Cannot be calculated", "0") %>%
           str_replace_all("(\\d+(\\.\\d+)?)\\s*[xX]\\s*10\\s*e([-+]?\\d+)", "\\1e\\3") %>%
           as.numeric())

#2.7 clean columns 6, 8:20
PPDB_Ingred <- PPDB_Ingred %>%
  mutate(across(c(6, 8:20), ~ {
    .x %>%
      str_replace_all(c("Low risk" = "0", "-" = "0", "Stable" = "0", "No data" = "0")) %>%
      replace_na("0") %>%
      str_replace_all("[<>]=|[=><]", "") %>%
      as.numeric()
  }))

#2.8 calculate the concentration
PPDB_Ingred <- PPDB_Ingred %>%
  mutate(Gehalt_Main = ifelse(Gehalt_Main == "", 0, Gehalt_Main)) %>%
  mutate(Gehalt_Main = gsub(",", "", Gehalt_Main)) %>% 
  mutate(Gehalt_Main = as.numeric(Gehalt_Main),
         concentration = Gehalt_Main / 1000)

#2.9 create ingred_products data frame
ingred_products <- PPDB_Ingred %>%
  select(Zulassungsnr = Zulassungsnr,
         product = Handelsbezeichnung,
         substance = Wirkstoff_Main,
         Wirkungsbereich = Wirkungsbereich,
         crop = crop,
         health = Code) %>%
  mutate(reference.sum.risk.scores = 300,
         formula = 1)

#2.10 create ingred_substances data frame
ingred_substances <- PPDB_Ingred %>%
  select(Zulassungsnr = Zulassungsnr,
         product = Handelsbezeichnung,
         substance = Wirkstoff_Main,
         SCI.Grow = SCI.Grow,
         concentration = concentration,
         c(6, 8:20))


# Task 3 Calculate the PLI######################################################

#3.1 define load factors
Load.factors <- c("Load.Factor.SCI","Load.Factor.BCF","Load.Factor.SoilDT50",
                  "Load.Factor.Birds","Load.Factor.Mammals","Load.Factor.Fish",
                  "Load.Factor.Aquatic.Invertebrates","Load.Factor.Algae","Load.Factor.Aquatic.Plants",
                  "Load.Factor.Earthworms","Load.Factor.Bees","Load.Factor.Fish.Chronic",
                  "Load.Factor.Aquatic.Invertebrates.Chronic","Load.Factor.Earthworms.Chronic")

#3.2 define reference factors
Reference.factor <-c("Reference.SCI.Grow", "Reference.BCF", "Reference.SoilDT50",
                     "Reference.Value.Birds", "Reference.Value.Mammals", "Reference.Value.Fish",
                     "Reference.Value.Aquatic.Invertebrates", "Reference.Value.Algae", "Reference.Value.Aquatic.Plants",
                     "Reference.Value.Earthworms", "Reference.Value.Bees", "Reference.Value.Fish.Chronic",
                     "Reference.Value.Aquatic.Invertebrates.Chronic", "Reference.Value.Earthworms.Chronic")


#3.3 include load factors in the substance data frame
for (i in 1:length(Load.factors)){
  ingred_substances[,Load.factors[i]]<- rep(times=dim(ingred_substances)[[1]],
                                            substances.load()[1,Load.factors[i]])
}
  
#3.4 include reference factors in the substance data frame
for (i in 1:length(Reference.factor)){
  ingred_substances[,Reference.factor[i]]<- rep(times=dim(ingred_substances)[[1]], 
                                                substances.load()[1,Reference.factor[i]])
}

#3.5 remove duplicate items
ingred_products <- ingred_products %>%
  distinct(product, .keep_all = TRUE)

ingred_substances <- ingred_substances %>%
  distinct(product, .keep_all = TRUE)
  
#3.6 calculate the sum of risk scores for products
ingred_products <- compute_risk_score(ingred_products, "health")
  
#3.7 replace NA values in sum risk score by 0
ingred_products <- ingred_products %>% 
  mutate(sum.risk.score = replace_na(sum.risk.score, 0))
  
#3.8 compute PLI (Pesticide Load Indicator)
ingred_indicators <- compute_pesticide_load_indicator(substances = ingred_substances, products = ingred_products)

#3.9 join ingred_indicators and bvl_ingred
ingred_indicators <- ingred_indicators %>%
  select(Zulassungsnr, product, Wirkungsbereich, crop, health,
         reference.sum.risk.scores, formula, sum.risk.score, HL, TL, FL, L) %>% 
  rename(PLI = L) %>% 
  mutate(
    crop = replace(crop, crop %in% c("N/A", "-"), NA)
  )

#3.10 write output
write.csv(ingred_indicators, "PPDB/Pesticides_PLI.csv", row.names = FALSE)


#Task 4 Address products without hazard code (Optional)#########################

# Users can create a list of pesticides without a hazard code (steps 4.1 and 4.2) and use GHS_code.py to scrape the BVL database. 
# Then, users can load the scraped results (step 4.3) and recalculate the PLI (steps 4.4 to 4.10).
# However, this task is a showcase only. As all health codes are now sourced from the BVL database, 
# it may be unnecessary to re-scrape the BVL database for any pesticides missing health codes.
# 
# #4.1 select the product without health index
# GHS_list <- ingred_products %>%
#   filter(is.na(health)) %>% 
#   select(product) %>% 
#   distinct()
# 
# #4.2 save the result to CSV for scraping using GHS_code.py
# write.csv(GHS_list, "PPDB/GHS_list.csv", row.names = FALSE)
# 
# #4.3 load the scraping result and the info for hazard code
# GHS_result <- read.csv("PPDB/GHS_result.csv")
# 
# #4.4 clean the result
# GHS_result <- GHS_result %>% 
#   filter(GHS != "N/A") %>% 
#   separate_rows(GHS, sep = "\n")
# 
# #4.5 join the GHS tables
# GHS_result <- GHS_result %>% 
#   left_join(GHS_code, by = c("GHS" = "Wortlaut")) %>% 
#   filter(!is.na(Code)) %>%
#   group_by(Zulassungsnr) %>%
#   summarize(
#     GHS = paste(GHS, collapse = " "),
#     Code = paste(Code, collapse = ",")
#   ) %>%
#   ungroup()
# 
# #4.6 join the GHS_result with ingred_products
# ingred_products <- ingred_products %>% 
#   left_join(GHS_result , by = "Zulassungsnr")
# 
# #4.7 replace health with Code when health is NA
# ingred_products <- ingred_products %>%
#   mutate(health = ifelse(is.na(health), Code, health)) %>% 
#   select(-c(GHS, Code)) %>% 
#   distinct(product, .keep_all = TRUE)
# 
# #4.8 compute PLI (Pesticide Load Indicator)
# ingred_indicators <- compute_pesticide_load_indicator(substances = ingred_substances, products = ingred_products)
# 
# #4.9 join ingred_indicators and bvl_ingred
# ingred_indicators <- ingred_indicators %>%
#   select(Zulassungsnr, product, Wirkungsbereich, crop, health, 
#          reference.sum.risk.scores, formula, sum.risk.score, HL, TL, FL, L) %>% 
#   rename(PLI = L) %>% 
#   mutate(
#     crop = replace(crop, crop %in% c("N/A", "-"), NA)
#   )
# 
# #4.10 write output
# write.csv(ingred_indicators, "MLR_Queries_Calculations/PPDB/Pesticides_PLI.csv", row.names = FALSE)