#1. Import necessary libraries
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
from bs4 import BeautifulSoup, SoupStrainer
import pandas as pd


#2. Set the working directory and output file type
output_dir = '../Pesticide_Info'  # Directory to save the output CSV
output_file_name = 'Pesticide_Info.csv'


#3. Base URL and session initialization
"""Since each search will initialise a new session, thus it is necessary to establish and maintain a valid session."""
base_url = "https://psm-zulassung.bvl.bund.de/psm/jsp/"
session = requests.Session()


#4. Implement Retry Logic with Backoff
"""
It is constructed to handle abrupt disconnection to the web server and help recover from intermittent issues.
Based on my experience, fewer than 10 pesticides require a second attempt to retrieve data, and none require a third attempt.
"""
retries = Retry(total=5, backoff_factor=1, status_forcelist=[ 429, 500, 502, 503, 504 ])


#5. Attach an HTTPAdapter with the retry strategy to HTTP and HTTPS session
session.mount('http://', HTTPAdapter(max_retries=retries))
session.mount('https://', HTTPAdapter(max_retries=retries))


#6. Set headers to mimic a typical browser request
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
}


#7. Function for retry mechanism and pause between requests
"""Make a GET request with automatic retries and delays. It is constructed consistent with the retry logic."""

def robust_request(url):
    try:
        response = session.get(url, headers=headers)
        response.raise_for_status()  # will not proceed if the request returned an HTTP error
        return response
    
    except requests.exceptions.HTTPError as e:
        print(f"HTTP error: {e}")
        
    except requests.exceptions.ConnectionError as e:
        print(f"Connection error: {e}")
        
    except requests.exceptions.Timeout as e:
        print(f"Timeout error: {e}")
        
    except requests.exceptions.RequestException as e:
        print(f"Error during requests to {url} : {e}")
        
    return None


#8. Function to get the main list URL from the index page
"""
The scraping procedure starts with initialising a new session on the index page. The function mimics "click" on the button "Gesamtliste" to view the full list
of pesticides. By construction, the button is within an iFrame. Thus, we must identify the iframe and fetch its "src" attribute to access the URL where the content is loaded.
Next, we can request that URL to fetch the content where the "Gesamtliste" link resides.
"""
def get_main_list_url():
    index_url = "https://psm-zulassung.bvl.bund.de/psm/jsp/index.jsp"
    response = session.get(index_url, headers=headers)
    soup = BeautifulSoup(response.text, 'lxml')
    iframe = soup.find('iframe')
    
    if iframe:
        iframe_src = f"{base_url}{iframe['src']}"
        iframe_response = session.get(iframe_src, headers=headers)
        iframe_soup = BeautifulSoup(iframe_response.text, 'lxml')
        main_list_element = iframe_soup.find('a', string="Gesamtliste")
        
        if main_list_element:
            main_list_url = f"{base_url}{main_list_element['href']}"
            return main_list_url
        else:
            raise Exception("The 'Gesamtliste' link was not found in the iframe content.")
        
    else:
        raise Exception("No iframe found on the index page.")


#9. Function to scrape data from a single pesticide page
def scrape_pesticide_data(pesticide_url):
    response = robust_request(pesticide_url)
    
    if response:
        strainer = SoupStrainer('td', class_=['label','value'])
        soup = BeautifulSoup(response.text, 'lxml',parse_only=strainer)
        data = {
            'Zulassungsnr': get_text_by_label(soup, "Zulassungsnummer"),
            'Handelsbezeichnung': get_text_by_label(soup, "Handelsbezeichnung"),
            'Zulassungsende': get_text_by_label(soup, "Zulassungsende"),
            'Wirkungsbereich': get_text_by_label(soup, "Wirkungsbereich"),
            'Wirkstoffgehalt': get_text_by_label(soup, "Wirkstoffgehalt"),
            'Hinweise': get_text_by_label(soup, "Hinweise"),
            "GHS": get_text_by_label(soup, "Gefahrenhinweise (GHS)")
        }
        return data
    
    else:
        return None  # or an empty dictionary {}


#10. Function to safely extract text
"""
This function safely attempts to find text based on a given label and handles cases where the element might not be found.
This prevents the script from crashing and allows it to continue even if some data points are missing or formatted unexpectedly.
"""
def get_text_by_label(soup, label):
    """Safely extract text by the label from the soup object."""
    element = soup.find('td', string=lambda text: text and label in text)
    
    if element and element.find_next('td'):
        return element.find_next('td').text.replace('<br>', ' ').strip()
    
    return "N/A"


#11. Function to scrape the data on the first page
"""Retrieve pesticide links from the first page."""

def get_pesticide_links_from_first_page(main_list_url):
    response = session.get(main_list_url, headers=headers)
    strainer = SoupStrainer('tr', class_=lambda x: x in ['row1', 'row0'])
    soup = BeautifulSoup(response.text, 'lxml', parse_only=strainer)
    links = soup.find_all('a', id="Datenblatt")
    first_page_links = {}

    for link in links:
        name = link.text.strip()
        trade_number = link['href'].split('=')[-1]  # Assumes trade number is part of the URL query
        unique_key = f"{name} {trade_number}"  # Create a unique key
        first_page_links[unique_key] = f"{base_url}{link['href']}"
    return first_page_links


#12. Function to parse main list page and get all pesticide links starting from page 2 to 68
"""
The URLs differ for the first page, which initialises a new session, and the rest. Therefore, looping all pages by altering
page=1 to page=2 isn't easy. It's better to scrape the data separately.
"""
def get_pesticide_links():
    all_links = {}
    
    # Start from page 2 as page 1 is handled separately
    for page in range(2, 69):
        page_url = f"{base_url}ListeMain.jsp?page={page}"
        print(f"Fetching page {page}: {page_url}")  # Debugging print
        response = session.get(page_url, headers=headers)
        
        if response.status_code == 200:
            strainer = SoupStrainer('tr', class_=lambda x: x in ['row1', 'row0'])
            soup = BeautifulSoup(response.text, 'lxml', parse_only=strainer)
            links = soup.find_all('a', id="Datenblatt")
            print(f"Found {len(links)} links on page {page}")  # Debugging print
            
            for link in links:
                name = link.text.strip()
                trade_number = link['href'].split('=')[-1]  # Extract trade number from the URL
                unique_key = f"{name} {trade_number}"  # Combine name and trade number for a unique key
                all_links[unique_key] = f"{base_url}{link['href']}"
                # print(f"Added {unique_key}: {all_links[unique_key]}")  # Debugging print
        else:
            print(f"Failed to fetch page {page}, status code: {response.status_code}")
            
    return all_links


#13. Main function to coordinate the scraping process
def main_scraping_process():
    # Initialize the session and get the URL for the first page
    main_list_url = get_main_list_url()  # This gets the URL that starts the session and points to the first page
    print(f"URL for the first page: {main_list_url}")  # Debug print

    # Scrape data from the first page
    all_pesticide_data = []
    first_page_links = get_pesticide_links_from_first_page(main_list_url)  # Function to get links from the first page
    
    for name, url in first_page_links.items():
        first_page_data = scrape_pesticide_data(url)
        all_pesticide_data.append(first_page_data)
        
    # Continue scraping from page 2 to 68
    subsequent_pages_links = get_pesticide_links()
    for name, url in subsequent_pages_links.items():
        
        try:
            pesticide_data = scrape_pesticide_data(url)
            all_pesticide_data.append(pesticide_data)
            
        except Exception as e:
            print(f"Failed to scrape data for {name}: {str(e)}")

    # Save all collected data to CSV
    df = pd.DataFrame(all_pesticide_data)
    df.to_csv(f"{output_dir}/{output_file_name}", index=False)
    print("Scraping completed and data saved to CSV.")


#14. Run the function
main_scraping_process()
