rm(list = ls())
cat("\014")

setwd("PATH")

#1. load necessary package
library(data.table)
library(tidyverse)
library(openxlsx)
library(purrr)

#2. load the data
bvl_ingred <- fread("BVL_Ingredients.csv")

#3 create normalized input for further matching

#3.1 define the list of specific names and their normalized forms
name_mapping <- c(#HRAC
  "Mesosulfuron" = "Mesosulfuron-methyl",
  "Metsulfuron" = "Metsulfuron-methyl",
  "Iodosulfuron" = "Iodosulfuron-methyl-Na",
  "Thiencarbazone" = "Thiencarbazone-methyl",
  "Thifensulfuron" = "Thifensulfuron-methyl",
  "Tribenuron" = "Tribenuron-methyl",
  "Carfentrazone" = "Carfentrazone-ethyl",
  "Fenoxaprop-P" = "Fenoxaprop-ethyl",
  "Quizalofop-P" = "Quizalofop-ethyl",
  "Pyraflufen" = "Pyraflufen-ethyl",
  "Fluazifop-P" = "Fluazifop-butyl",
  "Mecoprop-P" = "Mecoprop",
  "Glyphosat" = "Glyphosate",
  "Napropamid" = "Napropamide",
  "Terbuthylazin" = "Terbuthylazine",
  "Propyzamid" = "Propyzamide=pronamide",
  "Propoxycarbazone" = "Propoxycarbazone-Na",
  "Ethofumesat" = "Ethofumesate",
  "Halauxifen-methyl" = "Halauxifen",
  "Pyridat" = "Pyridate",
  "Dimethenamid-P" = "Dimethenamid",
  "Dichlorprop-P" = "Dichlorprop",
  "Ethofumesat" = "Ethofumesate",
  "Napropamid" = "Napropamide",
  "Florpyrauxifen-benzyl" = "Florpyrauxifen",
  "Sulcotrion" = "Sulcotrione",
  
  #FRAC
  "Prothioconazol" = "Prothioconazole",
  "Fosetyl" = "Fosetyl-Al",
  "Bromuconazol" = "Bromuconazole",
  "Dimethomorph" = "Dimethomorph (& List Of Caas)",
  "Metconazol" = "Metconazole",
  "Difenoconazol" = "Difenoconazole",
  "Bacillus amyloliquefaciens subsp. plantarum Stamm D747 50.000.000.000.000cfu/kg" = "Bacillus Mycoides Isolate J",
  "Bacillus amyloliquefaciens Stamm QST 713 (vormals B. subtilis) 1.000.000.000.000cfu/kg" = "Bacillus Mycoides Isolate J",
  "Bacillus amyloliquefaciens Stamm MBI 600 55.000.000.000.000cfu/kg" = "Bacillus Mycoides Isolate J",
  "Bacillus amyloliquefaciens Stamm MBI 600 22.000.000.000.000cfu/l" = "Bacillus Mycoides Isolate J",
  "Bacillus amyloliquefaciens Stamm FZB24 10.000.000.000.000cfu/kg" = "Bacillus Mycoides Isolate J",
  "Tebuconazol" = "Tebuconazole",
  "Thiabendazol" = "Thiabendazole",
  "Cyprodinil" = "Cyprodinil (& List Of Aps)",
  "Kresoxim-methyl" = "Kresoxim-Methyl",
  "Imazalil" = "Imazalil (& List Of Dmis)",
  "Dodin" = "Dodine",
  "Benalaxyl-M" = "Benalaxyl-M (=Kiralaxyl)",
  "Metalaxyl-M" = "Metalaxyl-M (=Mefenoxam)",
  "Fenpyrazamine" = "Fenpyrazamine (& List Of Kris)",
  "Oxathiapiprolin" = "Oxathiapiprolin (& List Of Osbpis)",
  "Cyazofamid" = "Cyazofamid (& List Of Qiis)",
  "Bupirimat" = "Bupirimate",
  "Cerevisane" = "S Cerevisae: Strain Las02",
  "Triticonazol" = "Triticonazole",
  "Penconazol" = "Penconazole",
  "Hymexazol" = "Hymexazole",
  
  #IRAC
  "Pyrethrine" = "Pyrethrins (pyrethrum)",
  "Bacillus thuringiensis subspecies kurstaki Stamm ABTS-351 (Stamm HD-1) (33,2 g/l Grundkörper) 17.600IU/mg" = "Bacillus thuringiensis",
  "Bacillus thuringiensis subspecies kurstaki Stamm ABTS-351 (Stamm HD-1) 11.700.000.000.000cfu/kg" = "Bacillus thuringiensis",
  "Bacillus thuringiensis subspecies aizawai Stamm ABTS-1857 (540 g/kg Grundkörper) 15.000IU/mg" = "Bacillus thuringiensis",
  "Bacillus thuringiensis subspecies kurstaki Stamm ABTS-351 (Stamm HD-1) 16.700IU/mg" = "Bacillus thuringiensis",
  "Bacillus thuringiensis subsp. israelensis (Serotyp H-14) AM65-52 5.600.000.000.000cfu/l" = "Bacillus thuringiensis",
  "Bacillus thuringiensis subspecies kurstaki Stamm EG-2348 32.000IU/mg" = "Bacillus thuringiensis",
  "Bacillus thuringiensis subspecies aizawai Stamm GC-91 25.000IU/mg" = "Bacillus thuringiensis",
  "Cydia pomonella Granulovirus mexikanisches Isolat 10.000.000.000.000Granula je l" = "Cydia pomonella GV",
  "Cydia pomonella Granulovirus Isolat GV-R5 10.000.000.000.000Granula je l" = "Cydia pomonella GV",
  "Cydia pomonella Granulovirus Isolat GV-0013 (Isolat V15) 2.500.000.000.000Granula je l" = "Cydia pomonella GV",
  "Cydia pomonella Granulovirus Isolat GV-0006 30.000.000.000.000Granula je l" = "Cydia pomonella GV",
  "Cydia pomonella Granulovirus Isolat GV-0013 (Isolat V15) 30.000.000.000.000Granula je l" = "Cydia pomonella GV",
  "tau-Fluvalinat" = "tau-Fluvalinate",
  "Metarhizium brunneum Stamm Ma 43 (vormals M. anisopliae F52) 900.000.000.000cfu/kg" = "Metarhizium brunneum  strain  F52",
  "Metarhizium brunneum Stamm Ma 43 (vormals M. anisopliae F52) 2.000.000.000.000cfu/l" = "Metarhizium brunneum Stamm Ma 43 (vormals M. anisopliae F52) 2.000.000.000.000cfu/l",
  "Tebufenozid" = "Tebufenozide",
  "Beauveria bassiana Stamm ATCC 74040 23.000.000.000cfu/l" = "Beauveria bassiana strains",
  "Beauveria bassiana Stamm PPRI 5339 8.000.000.000.000cfu/l" = "Beauveria bassiana strains")

#3.2 create a normalization function
normalize_name <- function(name_column) {
  str_replace_all(name_column, fixed(name_mapping))
}

#3.3 apply the normalization to the 'Wirkstoff_Main' column in bvl_ingred
bvl_ingred <- bvl_ingred %>%
  mutate(Normalized_Wirkstoff = normalize_name(Wirkstoff_Main))

#4. HRAC

#4.1 load the data
HRAC <- read.xlsx("HRAC/2024-HRAC-Global-Herbicide-MoA-Classification-Master-List.xlsx")

#4.2 create a subtable matching 'Wirkstoff' with 'ACTIVE' from HRAC
bvl_HRAC <- bvl_ingred %>%
  filter(Wirkungsbereich == "Herbizid")%>%
  
  # Perform a left join on bvl_ingred with the relevant part of HRAC
  left_join(mutate(HRAC, ACTIVE = str_trim(ACTIVE)), by = c("Normalized_Wirkstoff" = "ACTIVE")) %>%
  select(Zulassungsnr, Wirkungsbereich, Wirkstoff_Main, Gehalt_Main, Einhalt_Main, 
         Wirkstoff_Compound, Gehalt_Compound, Einhalt_Compound, Organismus_Bakteria, HRAC)

# #4.3 filter the dataframe to get rows where HRAC is NA
# NA_HRAC <- bvl_HRAC %>%
#   filter(is.na(HRAC)) %>%
#   select(Wirkstoff_Main) %>%
#   distinct()
 
#4.4 write ouput as csv
fwrite(bvl_HRAC, "HRAC/BVL_HRAC.csv")

#5. FRAC

#5.1 load the data
FRAC <- read.xlsx("FRAC/FRAC MOA CODE LIST EXCEL 2024_FINAL.xlsx")

#5.2 adjust the case of `(ISO).Common.Name`
FRAC <- FRAC %>%
  mutate(`(ISO).Common.Name` = str_to_title(`(ISO).Common.Name`))

#5.3 create a subtable matching 'Wirkstoff' with '(ISO) common name' from FRAC
bvl_FRAC <- bvl_ingred %>%
  filter(Wirkungsbereich == "Fungizid") %>%
  left_join(mutate(FRAC, `(ISO).Common.Name` = str_trim(`(ISO).Common.Name`)), by = c("Normalized_Wirkstoff" = "(ISO).Common.Name")) %>%
  select(Zulassungsnr, Wirkungsbereich, Wirkstoff_Main, Gehalt_Main, Einhalt_Main, 
         Wirkstoff_Compound, Gehalt_Compound, Einhalt_Compound, Organismus_Bakteria, FRAC.Group.Code, MOA, Comments)

# #5.4 filter the dataframe to get rows where HRAC is NA
# NA_FRAC <- bvl_FRAC %>%
#   filter(is.na(FRAC.Group.Code)) %>%
#   select(Wirkstoff_Main) %>%
#   distinct()

#5.5 write ouput as csv
fwrite(bvl_FRAC, "FRAC/BVL_FRAC.csv")

#6. IRAC

#6.1 define the base directory where the files are stored
base_dir <- "IRAC/Insecticide_Table/"

#6.2 generate all possible combinations of page numbers and table numbers
pages <- 35:42
tables <- 1:2

#6.3 create file paths, noting that the last page has only one table
file_paths <- unlist(lapply(pages, function(page) {
  if (page == 42) {
    return(paste0(base_dir, "IRAC-page-", page, "-table-1.csv"))
  } else {
    return(paste0(base_dir, "IRAC-page-", page, "-table-", tables, ".csv"))
  }
}))

#6.4 read all CSV files and combine into one dataframe
IRAC <- map_df(file_paths, ~read_csv(.x, show_col_types = FALSE), .id = "source")

#6.5 change the column name
names(IRAC) <- gsub("MOA \\nNo\\.", "MOA No.", names(IRAC))

#6.6 further cleaning
IRAC <- IRAC %>%
  
  # Replace line breaks and double spaces with a single space
  mutate(`Active Ingredient` = str_replace_all(`Active Ingredient`, "\\s{2,}|\\n", " ")) %>% 
  
  # Replace specific spaces in "l ambda-Cyhalothrin" and "a l pha-Cypermethrin"
  mutate(`Active Ingredient` = str_replace_all(`Active Ingredient`, c("l ambda-Cyhalothrin" = "lambda-Cyhalothrin", 
                                                                      "a l pha-Cypermethrin" = "alpha-Cypermethrin")))

#6.7 create a subtable matching 'Wirkstoff' with 'Active Ingredient' from IRAC
bvl_IRAC <- bvl_ingred %>%
  filter(Wirkungsbereich == "Insektizid") %>%
  left_join(IRAC, by = c("Normalized_Wirkstoff" = "Active Ingredient")) %>%
  select(Zulassungsnr, Wirkungsbereich, Wirkstoff_Main, Gehalt_Main, Einhalt_Main, 
         Wirkstoff_Compound, Gehalt_Compound, Einhalt_Compound, Organismus_Bakteria, `MOA No.`)

# #6.8 filter the dataframe to get rows where HRAC is NA
# NA_IRAC <- bvl_IRAC %>%
#   filter(is.na(`MOA No.`)) %>%
#   select(Wirkstoff_Main) %>%
#   distinct()

#6.9 write ouput as csv
fwrite(bvl_IRAC, "IRAC/BVL_IRAC.csv")
 
# #7. drop the normalized name after mapping (optional)
# bvl_ingred <- bvl_ingred[, -10]
