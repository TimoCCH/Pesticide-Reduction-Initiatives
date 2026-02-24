1. # Import necessary libraries
import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
import logging
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


#2. Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


#3. Configuration
CONFIG = {
    "input_file": 'D:/University/Hiwi/Land Use Economics/Work/Pesticide Reduction Initiatives/PPDB/Ingred_list.csv',
    "output_file": 'D:/University/Hiwi/Land Use Economics/Work/Pesticide Reduction Initiatives/PPDB/PPDB_Ingred.csv',
    "unmatched_file": 'D:/University/Hiwi/Land Use Economics/Work/Pesticide Reduction Initiatives/PPDB/Unmatched_Pesticides.csv',
    "main_url": 'https://sitem.herts.ac.uk/aeru/ppdb/en/atoz.htm',
    "base_url": 'https://sitem.herts.ac.uk/aeru/ppdb/en/',
    "other_urls": [
        'https://sitem.herts.ac.uk/aeru/ppdb/en/atoz_insect.htm',
        'https://sitem.herts.ac.uk/aeru/ppdb/en/atoz_herb.htm',
        'https://sitem.herts.ac.uk/aeru/ppdb/en/atoz_fung.htm',
        'https://sitem.herts.ac.uk/aeru/ppdb/en/atoz_other.htm'
    ]
}


#4. Read the pesticides data from CSV
# logging.info("Reading pesticides data from CSV...") debugging
pesticides_df = pd.read_csv(CONFIG["input_file"])
logging.info(f"Read {len(pesticides_df)} pesticides from CSV.")
substances = pesticides_df['Normalized_Wirkstoff'].tolist()


#5. Retry logic for requests
retry_strategy = Retry(
    total=3,
    backoff_factor=1,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["HEAD", "GET", "OPTIONS"]
)
adapter = HTTPAdapter(max_retries=retry_strategy)
http = requests.Session()
http.mount("https://", adapter)
http.mount("http://", adapter)


#6. Function to get text from an HTML element
def get_text_from_element(soup, label, data_class='data3', default_value="N/A"):
    try:
        element = soup.find('td', class_='row_header', string=label)
        if element:
            data_element = element.find_next('td', class_=data_class)
            if data_element:
                # Handle <sup> tags for scientific notation
                if data_element.find('sup'):
                    base_text = data_element.get_text(strip=True, separator=' ')
                    sup_text = data_element.find('sup').get_text(strip=True)
                    return f"{base_text.replace(sup_text, '')}e{sup_text}"
                else:
                    return data_element.text.strip()       
        return default_value
    except AttributeError as e:
        logging.error(f"Error extracting data for label {label}: {e}")
        return default_value


#7. Function to scrape the main page and find links to pesticides
def get_pesticide_links(url, substances):
    
    # logging.info(f"Fetching main page {url} to get pesticide links...") debugging
    response = http.get(url)
    response.raise_for_status()
    # logging.info("Main page fetched successfully.") debugging
    soup = BeautifulSoup(response.text, 'lxml')
    
    links = []
    found_substances = []
    for a_tag in soup.find_all('a', href=True):     
        if 'target' in a_tag.attrs and a_tag['target'] == '_top':
            name = a_tag.text.strip()       
            found_substances.append(name)
            if name in substances:
                # logging.info(f"Found matching pesticide: {name}") debugging        
                links.append((name, CONFIG["base_url"] + a_tag['href']))    
    unmatched_substances = [substance for substance in substances if substance not in found_substances]
    logging.info(f"Total matching pesticide links found: {len(links)}")
    logging.info(f"Total unmatched pesticides: {len(unmatched_substances)}")
    
    return links, unmatched_substances


#8. Function to scrape details of each pesticide
def get_pesticide_details(pesticide_url):
    
    # logging.info(f"Fetching details for pesticide at URL: {pesticide_url}") debugging
    response = http.get(pesticide_url)
    response.raise_for_status()
    # logging.info("Details page fetched successfully.") debugging
    soup = BeautifulSoup(response.text, 'lxml')
    
    details = {
        'Example applications': get_text_from_element(soup, 'Example applications', data_class='data1'),
        'CAS': get_text_from_element(soup, 'CAS RN', data_class='data1'),
        'CLP': get_text_from_element(soup, 'CLP classification 2013', data_class='data1'),
        'BCF': get_text_from_element(soup, 'Bio-concentration factor'),
        'SCI_GROW': get_text_from_element(soup, 'SCI-GROW groundwater index (μg l⁻¹) for a 1 kg ha⁻¹ or 1 l ha⁻¹ application rate'),
        'Soil_DT50': get_text_from_element(soup, 'Soil degradation (days) (aerobic)'),
        'Birds_Acute_LD50': get_text_from_element(soup, 'Birds - Acute LD₅₀ (mg kg⁻¹)'),
        'Mammals_Acute_Oral_LD50': get_text_from_element(soup, 'Mammals - Acute oral LD₅₀ (mg kg⁻¹)'),
        'Earthworms_Acute_14d_LC50': get_text_from_element(soup, 'Earthworms - Acute 14 day LC₅₀ (mg kg⁻¹)'),
        'Earthworms_Chronic_NOEC_Reproduction': get_text_from_element(soup, 'Earthworms - Chronic NOEC, reproduction (mg kg⁻¹)'),
        'Bees_LD50': get_text_from_element(soup, 'Contact acute LD₅₀ (worst case from 24, 48 and 72 hour values - μg bee⁻¹)'),
        'Fish_Acute_96hr_LC50': get_text_from_element(soup, 'Temperate Freshwater Fish - Acute 96 hour LC₅₀ (mg l⁻¹)'),
        'Fish_Chronic_21d_NOEC': get_text_from_element(soup, 'Temperate Freshwater Fish - Chronic 21 day NOEC (mg l⁻¹)'),
        'Invertebrates_Acute_48hr_EC50': get_text_from_element(soup, 'Temperate Freshwater Aquatic invertebrates - Acute 48 hour EC₅₀ (mg l⁻¹)'),
        'Invertebrates_Chronic_21d_NOEC': get_text_from_element(soup, 'Temperate Freshwater Aquatic invertebrates - Chronic 21 day NOEC (mg l⁻¹)'),
        'Aquatic_Plants_Acute_7d_EC50': get_text_from_element(soup, 'Aquatic plants (free-floating, growth) - Acute 7 day EC₅₀, biomass (mg l⁻¹)'),
        'Algae_Acute_72hr_EC50': get_text_from_element(soup, 'Algae - Acute 72 hour EC₅₀, growth (mg l⁻¹)'),
        'Water_Phase_DT50': get_text_from_element(soup, 'Water phase only DT₅₀ (days)')
    }

    return list(details.values())


#9. Function to scrape data from a list of links
def scrape_links(links, scraped_data):
    for substance, link in links:
        logging.info(f"Scraping data for {substance} from {link}")
        try:
            details = get_pesticide_details(link)
            if len(details) == 18:
                scraped_data.append({
                    'substance': substance,
                    'crop': details[0],
                    'CAS': details[1],
                    'CLP': details[2],
                    'BCF': details[3],
                    'SCI.Grow': details[4],
                    'SoilDT50': details[5],
                    'Birds.Acute.LD50.mg.kg': details[6],
                    'Mammals.Acute.Oral.LD50.mg.kg.BW.day': details[7],
                    'Earthworms.Acute.14d.LC50.mg.kg': details[8],
                    'Earthworms.Chronic.14d.NOEC..Reproduction.mg.kg.corrected': details[9],
                    'BeesLD50': details[10],
                    'Fish.Acute.96hr.LC50.mg.l': details[11],
                    'Fish.Chronic.21d.NOEC.mg.l.corrected': details[12],
                    'Aquatic.Invertebrates.Acute.48hr.EC50.mg.l': details[13],
                    'Aquatic.Invertebrates.Chronic.21d.NOEC.mg.l.correted': details[14],
                    'Aquatic.Plants.Acute.7d.EC50.mg.l': details[15],
                    'Algae.Acute.72hr.EC50.Growth.mg.l': details[16],
                    'water.phase.DT50.days': details[17]
                })
            else:
                logging.warning(f"Data for {substance} is incomplete, skipping.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Failed to scrape data for {substance} due to request error: {e}")
        except Exception as e:
            logging.error(f"An error occurred while scraping data for {substance}: {e}")
        time.sleep(1)

        
#10. Main scraping process        
def main_scraping_process():
    
    start_time = time.time()
    # Get pesticide links from the main page
    pesticide_links, unmatched_substances = get_pesticide_links(CONFIG["main_url"], substances)
    scraped_data = []
    scrape_links(pesticide_links, scraped_data)

    # Create DataFrame and save to CSV
    logging.info("Saving scraped data to CSV...")
    output_df = pd.DataFrame(scraped_data)
    output_df.to_csv(CONFIG["output_file"], index=False)
    logging.info("Scraping completed and data saved to CSV.")
    
    # Scrape unmatched substances from the other URL
    for url in CONFIG["other_urls"]:
        if unmatched_substances:
            logging.info(f"Fetching unmatched substances from {url}...")
            other_links, remaining_unmatched_substances = get_pesticide_links(url, unmatched_substances)
            scrape_links(other_links, scraped_data)
            unmatched_substances = remaining_unmatched_substances

    # Save updated scraped data to CSV
    logging.info("Saving updated scraped data to CSV...")
    output_df = pd.DataFrame(scraped_data)
    output_df.to_csv(CONFIG["output_file"], index=False)
    logging.info("Updated scraping completed and data saved to CSV.")
    
    # Log remaining unmatched substances
    if unmatched_substances:
        logging.info("Logging remaining unmatched substances...")
        unmatched_df = pd.DataFrame(unmatched_substances, columns=['Unmatched_Substances'])
        unmatched_df.to_csv(CONFIG["unmatched_file"], index=False)
        logging.info(f"Remaining unmatched substances saved to {CONFIG['unmatched_file']}")
    
    end_time = time.time()
    logging.info(f"Total scraping process took {end_time - start_time:.2f} seconds.")


#11. Run the main process
if __name__ == '__main__':
    main_scraping_process()
