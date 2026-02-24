#1. Import necessary libraries
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import requests
import pandas as pd
import logging
import time
from itertools import product

#2. Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

#3. Configuration
CONFIG = {
    "url": "https://www.ktbl.de/webanwendungen/feldarbeitsrechner",
    "output_file": "C:/University/Hiwi/Land Use Economics/Work/WebScraping/MLR_Queries_Calculations/KTBL.csv"
}

#4. Use Beautiful Soup to find the base URL for the search session
logging.info("Fetching the base URL from the starting page...")
response = requests.get(CONFIG["url"])
response.raise_for_status()
soup = BeautifulSoup(response.text, "lxml")

feldarbeitsrechner_link = soup.find("a", href="https://daten.ktbl.de/feldarbeit/")
if feldarbeitsrechner_link:
    base_url = feldarbeitsrechner_link["href"]
    logging.info(f"Found base URL: {base_url}")
else:
    logging.error("Could not find the Feldarbeitsrechner link. Exiting.")
    exit()

#5. Setup Selenium WebDriver
driver = webdriver.Chrome()
driver.get(base_url)

#6. Main scraping process
try:
    # Navigate to the entry page by clicking "Feldarbeitsrechner starten"
    # logging.info("Waiting for 'Feldarbeitsrechner starten' button to load...")
    wait = WebDriverWait(driver, 10)
    start_button = wait.until(EC.presence_of_element_located((By.XPATH, "//input[@value='Feldarbeitsrechner starten']")))

    # logging.info("Clicking the 'Feldarbeitsrechner starten' button...")
    start_button.click()
    time.sleep(2)

    # Function to get user selections for Verfahrensgruppe and Arbeitsvorgang
    def get_user_selections():
        """Prompt user for Verfahrensgruppe and corresponding Arbeitsvorgang selections."""
        # logging.info("Fetching options for 'Verfahrensgruppe'...")
        verfahrensgruppe_dropdown = driver.find_element(By.NAME, "hgId")
        verfahrensgruppe_select = Select(verfahrensgruppe_dropdown)      
        verfahrensgruppe_options = [
            {"value": option.get_attribute("value"), "text": option.text.strip()}
            for option in verfahrensgruppe_select.options
            if option.get_attribute("value") != "0"
        ]
    
        # logging.info("Available 'Verfahrensgruppe' options fetched.")
        print("Available Verfahrensgruppe options:")
        for idx, option in enumerate(verfahrensgruppe_options):
            print(f"{idx + 1}. {option['text']}")
    
        # User selects multiple Verfahrensgruppe options
        verfahrensgruppe_choices = input(
            "Enter the numbers of your choices for Verfahrensgruppe (comma-separated, e.g., 1,2): "
        )
        verfahrensgruppe_choices = [
            verfahrensgruppe_options[int(idx) - 1] for idx in verfahrensgruppe_choices.split(",")
        ]
    
        # Dictionary to store Arbeitsvorgang choices for each Verfahrensgruppe
        selections = {}
    
        # Loop through selected Verfahrensgruppe to get corresponding Arbeitsvorgang choices
        for verfahrensgruppe in verfahrensgruppe_choices:
            verfahrensgruppe_text = verfahrensgruppe["text"]
            verfahrensgruppe_value = verfahrensgruppe["value"]
    
            # Recall the Verfahrensgruppe to fetch Arbeitsvorgang options
            logging.info(f"Selecting 'Verfahrensgruppe': {verfahrensgruppe_text}")
            verfahrensgruppe_dropdown = driver.find_element(By.NAME, "hgId")
            verfahrensgruppe_select = Select(verfahrensgruppe_dropdown)
            verfahrensgruppe_select.select_by_value(verfahrensgruppe_value)
            time.sleep(2)
    
            # Fetch Arbeitsvorgang options
            # logging.info("Fetching options for 'Arbeitsvorgang'...")
            arbeitsvorgang_dropdown = driver.find_element(By.NAME, "gId")
            arbeitsvorgang_select = Select(arbeitsvorgang_dropdown)
            arbeitsvorgang_options = [
                {"value": option.get_attribute("value"), "text": option.text.strip()}
                for option in arbeitsvorgang_select.options
                if option.get_attribute("value") != "0"
            ]
    
            # logging.info("Available 'Arbeitsvorgang' options fetched.")
            print(f"\nAvailable Arbeitsvorgang options for '{verfahrensgruppe_text}':")
            for idx, option in enumerate(arbeitsvorgang_options):
                print(f"{idx + 1}. {option['text']}")
    
            arbeitsvorgang_choices = input(
                f"Enter the numbers of your choices for Arbeitsvorgang under '{verfahrensgruppe_text}' (comma-separated, e.g., 1,2): "
            )
            arbeitsvorgang_choices = [
                arbeitsvorgang_options[int(idx) - 1] for idx in arbeitsvorgang_choices.split(",")
            ]
    
            # Store the selections
            selections[verfahrensgruppe_text] = {
                "value": verfahrensgruppe_value,
                "arbeitsvorgang_choices": arbeitsvorgang_choices
            }
    
        return selections
    
    # Prompt user for Verfahrensgruppe and Arbeitsvorgang selections
    selections = get_user_selections()
    
    # Initialize a list to store all data
    all_data = []

    # Define headers for the DataFrame
    headers = [
        "Verfahrensgruppe",
        "Arbeitsvorgang",
        "Maschinenkombination",
        "Schlaggröße [ha]",
        "Bodenbearbeitungswiderstand",
        "Entfernung zum Schlag [km]",
        "Menge [-/ha]",
        "Arbeitsbreite [m]",
        "Teilarbeit",
        "Arbeitszeitbedarf (Akh/ha)",
        "Flächenleistung (ha/h)",
        "Maschinenkosten: Abschreibung (€)",
        "Maschinenkosten: Zinskosten (€)",
        "Maschinenkosten: Sonstiges (€)",
        "Maschinenkosten: Reparaturen (€)",
        "Maschinenkosten: Betriebsstoffe (€)",
        "Dieselbedarf (l/ha)"
    ]

    def get_selected_option(name):
        """Retrieve the selected option text for a dropdown."""
        element = driver.find_element(By.NAME, name)
        select = Select(element)
        selected_option = select.first_selected_option
        return selected_option.text.strip()
    
    def get_user_dropdown_selections(dropdown_name, label):
        """Prompt user for selections from a dropdown."""
        dropdown = driver.find_element(By.NAME, dropdown_name)
        
        # Check if dropdown is enabled
        if not dropdown.is_enabled():
            logging.info(f"Dropdown '{label}' is disabled. Skipping selection.")
            return [None]  # Return a default value for disabled dropdowns
    
        select = Select(dropdown)
        options = [
            {"value": option.get_attribute("value"), "text": option.text.strip()}
            for option in select.options
            if option.get_attribute("value") != "0"
        ]
    
        print(f"\nAvailable options for {label}:")
        for idx, option in enumerate(options):
            print(f"{idx + 1}. {option['text']}")
    
        user_input = input(f"Enter the numbers of your choices for {label} (comma-separated, e.g., 1,2): ")
        selected_values = [options[int(idx) - 1]["value"] for idx in user_input.split(",")]
    
        return selected_values
    
    # Loop through Verfahrensgruppe and Arbeitsvorgang combinations
    for verfahrensgruppe_text, details in selections.items():
        try:
            verfahrensgruppe_value = details["value"]
            arbeitsvorgang_choices = details["arbeitsvorgang_choices"]
    
            # Recall Verfahrensgruppe
            logging.info(f"Selected 'Verfahrensgruppe': {verfahrensgruppe_text}")
            verfahrensgruppe_dropdown = driver.find_element(By.NAME, "hgId")
            verfahrensgruppe_select = Select(verfahrensgruppe_dropdown)
            verfahrensgruppe_select.select_by_value(verfahrensgruppe_value)
            time.sleep(2)
    
            # Loop through Arbeitsvorgang choices
            for arbeitsvorgang in arbeitsvorgang_choices:
                try:
                    arbeitsvorgang_text = arbeitsvorgang["text"]
                    arbeitsvorgang_value = arbeitsvorgang["value"]
    
                    # Recall Arbeitsvorgang
                    logging.info(f"Selected 'Arbeitsvorgang': {arbeitsvorgang_text}")
                    arbeitsvorgang_dropdown = driver.find_element(By.NAME, "gId")
                    arbeitsvorgang_select = Select(arbeitsvorgang_dropdown)
                    arbeitsvorgang_select.select_by_value(arbeitsvorgang_value)
                    time.sleep(2)
    
                    # Prompt user to choose specific Maschinenkombinationen
                    # logging.info(f"Fetching all 'Maschinenkombination' options for Arbeitsvorgang {arbeitsvorgang_text}...")
                    maschinenkombination_dropdown = driver.find_element(By.NAME, "avId")
                    maschinenkombination_select = Select(maschinenkombination_dropdown)
                    maschinenkombination_options = [
                        {"value": option.get_attribute("value"), "text": option.text.strip()}
                        for option in maschinenkombination_select.options
                        if option.get_attribute("value") != "0"
                    ]
                    
                    print(f"\nAvailable Maschinenkombination options for '{arbeitsvorgang_text}':")
                    for idx, option in enumerate(maschinenkombination_options):
                        print(f"{idx + 1}. {option['text']}")
                    
                    maschinenkombination_choices = input(
                        "Enter the numbers of your choices for Maschinenkombination (comma-separated, e.g., 1,3): "
                    )
                    maschinenkombination_choices = [
                        maschinenkombination_options[int(idx) - 1]["value"] for idx in maschinenkombination_choices.split(",")
                    ]           
                    # logging.info(f"Options for 'Maschinenkombination': {maschinenkombination_options}")
    
                    # Loop through each selected 'Maschinenkombination'
                    for maschinen_value in maschinenkombination_choices:
                        try:
                            # logging.info(f"Selecting 'Maschinenkombination' value: {maschinen_value}")
                            maschinenkombination_dropdown = driver.find_element(By.NAME, "avId")
                            maschinenkombination_select = Select(maschinenkombination_dropdown)
                            maschinenkombination_select.select_by_value(maschinen_value)
                            time.sleep(2)
                            
                            # Get user selections for each specification
                            user_selected_values = {
                                "flaecheID": get_user_dropdown_selections("flaecheID", "Schlaggröße"),
                                "bodenID": get_user_dropdown_selections("bodenID", "Bodenbearbeitungswiderstand"),
                                "hofID": get_user_dropdown_selections("hofID", "Entfernung zum Schlag"),
                                "mengeID": get_user_dropdown_selections("mengeID", "Menge"),
                                "arbeit": get_user_dropdown_selections("arbeit", "Arbeitsbreite"),
                            }
                    
                            # Now loop through only user-selected values instead of all combinations
                            for flaeche_value, boden_value, hof_value, menge_value, arbeit_value in product(
                                user_selected_values["flaecheID"], 
                                user_selected_values["bodenID"], 
                                user_selected_values["hofID"], 
                                user_selected_values["mengeID"], 
                                user_selected_values["arbeit"]
                            ):
                                try:
                                    # Select dropdown values for the current combination
                                    if flaeche_value is not None:
                                        flaecheID_dropdown = driver.find_element(By.NAME, "flaecheID")
                                        Select(flaecheID_dropdown).select_by_value(flaeche_value)
                                        time.sleep(1)
                            
                                    if boden_value is not None:
                                        bodenID_dropdown = driver.find_element(By.NAME, "bodenID")
                                        Select(bodenID_dropdown).select_by_value(boden_value)
                                        time.sleep(1)
                            
                                    if hof_value is not None:
                                        hofID_dropdown = driver.find_element(By.NAME, "hofID")
                                        Select(hofID_dropdown).select_by_value(hof_value)
                                        time.sleep(1)
                            
                                    if menge_value is not None:
                                        mengeID_dropdown = driver.find_element(By.NAME, "mengeID")
                                        Select(mengeID_dropdown).select_by_value(menge_value)
                                        time.sleep(1)
                            
                                    if arbeit_value is not None:
                                        arbeit_dropdown = driver.find_element(By.NAME, "arbeit")
                                        Select(arbeit_dropdown).select_by_value(arbeit_value)
                                        time.sleep(1)
                    
                                    # Click the 'aktualisieren' button to submit the form
                                    # logging.info("Clicking the 'aktualisieren' button to submit the form...")
                                    aktualisieren_button = driver.find_element(By.XPATH, "//input[@type='submit' and @value='aktualisieren']")
                                    aktualisieren_button.click()                  
                                    # logging.info("Form submitted successfully.")
                    
                                    # Scrape the table data
                                    # logging.info("Waiting for the 'tabs-2' section to load...")
                                    tabs_2 = wait.until(EC.presence_of_element_located((By.ID, "tabs-2")))
                                    soup = BeautifulSoup(driver.page_source, "lxml")
                                    table = soup.find("div", id="tabs-2").find("table")
                    
                                    if table:
                                        rows = table.find_all("tr")[1:]  # Skip the header rows
                                        # logging.info(f"Found {len(rows)} data rows in the table.")
                    
                                        for row in rows:
                                            cells = row.find_all("td")
                                            if len(cells) == 10:  # Ensure correct structure
                                                row_data = [
                                                    get_selected_option("hgId"),  # Verfahrensgruppe
                                                    get_selected_option("gId"),  # Arbeitsvorgang
                                                    get_selected_option("avId"),  # Maschinenkombination
                                                    get_selected_option("flaecheID"),  # Schlaggröße [ha]
                                                    get_selected_option("bodenID"),  # Bodenbearbeitungswiderstand
                                                    get_selected_option("hofID"),  # Entfernung zum Schlag [km]
                                                    get_selected_option("mengeID"),  # Menge [-/ha]
                                                    get_selected_option("arbeit"), # Arbeitsbreite [m]
                                                    cells[1].text.strip(),  # Teilarbeit
                                                    cells[2].text.strip(),  # Arbeitszeitbedarf
                                                    cells[3].text.strip(),  # Flächenleistung
                                                    cells[4].text.strip(),  # Maschinenkosten: Abschreibung
                                                    cells[5].text.strip(),  # Maschinenkosten: Zinskosten
                                                    cells[6].text.strip(),  # Maschinenkosten: Sonstiges
                                                    cells[7].text.strip(),  # Maschinenkosten: Reparaturen
                                                    cells[8].text.strip(),  # Maschinenkosten: Betriebsstoffe
                                                    cells[9].text.strip()   # Dieselbedarf
                                                ]
                                                all_data.append(row_data)
                                                # logging.info(f"Extracted row: {row_data}")
                                            else:
                                                logging.debug(f"Skipping non-data row with {len(cells)} cells: {cells}")
                    
                                    else:
                                        logging.warning("Table not found for this combination. Skipping data extraction.")
                    
                                except Exception as e:
                                    logging.error(f"Error processing combination: {e}")
                    
                        except Exception as e:
                            logging.error(f"Error selecting 'Maschinenkombination' value {maschinen_value}: {e}")
    
                except Exception as e:
                    logging.error(f"Error processing 'Arbeitsvorgang': {arbeitsvorgang_text}. Error: {e}")
    
        except Exception as e:
            logging.error(f"Error processing 'Verfahrensgruppe': {verfahrensgruppe_text}. Error: {e}")
    
    # Save the data
    logging.info("Converting all extracted data to a DataFrame...")
    df = pd.DataFrame(all_data, columns=headers)    
    output_excel_file = CONFIG["output_file"].replace(".csv", ".xlsx")
    df.to_excel(output_excel_file, index=False, engine="openpyxl")    
    
    logging.info(f"Data saved successfully to {output_excel_file}.")

except Exception as e:
    logging.error(f"An error occurred: {e}")

finally:
    # Close the browser
    driver.quit()