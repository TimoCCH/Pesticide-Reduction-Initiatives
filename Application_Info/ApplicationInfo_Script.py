#1. Import necessary libraries
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
from bs4 import BeautifulSoup, SoupStrainer
import pandas as pd


#2. Set the working directory and output file type
output_dir = '../Application_Info'
output_file_name = 'Application_Info.csv'


#3. Base URL and session initialization
"""Since each search will initialise a new session, thus it is necessary to establish and maintain a valid session."""
base_url = "https://psm-zulassung.bvl.bund.de/psm/jsp/"
session = requests.Session()


#4. Implement Retry Logic with Backoff
"""It is constructed to handle abrupt disconnection to the web server and help recover from intermittent issues."""
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
The scraping procedure starts with initialising a new session on the index page. The function mimics "click" on the button "Gesamtliste" to view the complete list
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
   

#9. Function to get details page URL from the application page
"""Retrieve all application detail URLs from the application page."""

def get_application_details_urls(app_page_url):
    response = session.get(app_page_url, headers=headers)

    if not response.ok:
        print(f"Failed to fetch the application page at {app_page_url}")
        return []

    strainer = SoupStrainer('tr', class_=lambda x: x in ['row1', 'row0'])
    soup = BeautifulSoup(response.text, 'lxml', parse_only=strainer)
    detail_urls = []

    for link in soup.find_all('a', href=True):

        if "BlattAnwendg.jsp" in link['href']:
            full_url = f"{base_url}{link['href']}"
            detail_urls.append(full_url)
    
    return detail_urls


#10. Function to scrape data from a single pesticide page
def scrape_application_details(detail_url):
    response = robust_request(detail_url)

    if response:
        # Strain to include <td> elements with 'label' or 'value' and also <div> elements
        strainer = SoupStrainer(lambda tag, attrs: (tag == 'td' and 'class' in attrs and ('label' in attrs['class'] or 'value' in attrs['class'])) or (tag == 'div'))
        soup = BeautifulSoup(response.text, 'lxml', parse_only=strainer)
        anwendungs_nr = detail_url.split('awg_id=')[-1].split('&')[0]
        data = {
            'Zulassungsnr': anwendungs_nr.split('/')[0],
            'Handelsbezeichnung': get_text_by_label(soup, "Handelsbezeichnung:"),
            'Anwendungsnr': anwendungs_nr,
            'Kultur/Objekt': get_text_by_label(soup, "Kultur/Objekt"),
            'Einsatzgebiet': get_text_by_label(soup, "Einsatzgebiet"),
            'Schadorganismus/Zweck': get_text_by_label(soup, "Schadorganismus/Zweck"),
            'Anwendungszeitpunkt': get_text_by_label(soup, "Anwendungszeitpunkt"),
            'Anwendungstechnik': get_text_by_label(soup, "Anwendungstechnik"),
            'Max. Zahl Behandlungen': get_text_by_label(soup, "Max. Zahl Behandlungen"),
            'Aufwand': get_text_by_label(soup, "Aufwand")
        }
        return data

    else:
        return None  # or an empty dictionary {}


#11. Function to safely extract text
"""
This function safely attempts to find text based on a given label and handles cases where the element might not be found.
This prevents the script from crashing and allows it to continue even if some data points are missing or formatted unexpectedly.
"""
def get_text_by_label(soup, label):
    """Safely extract text by the label from the soup object."""

    # Check for <div> elements that might contain the label as text within them
    div_element = soup.find('div', string=lambda text: text and label in text)
    if div_element:
        # Assuming label and value are separated by ':' and possibly other text
        return div_element.get_text().split(label)[-1].strip()
    
    else:

        # Other labels are in a <td class="label"> and their values in a subsequent <td class="value">
        element = soup.find('td', class_='label', string=label)
        if element and element.find_next_sibling('td', class_='value'):
            # Get the next sibling <td> tag and extract its text
            return element.find_next_sibling('td', class_='value').get_text(separator=' ', strip=True).replace('<br>', ' ').replace('<br/>', ' ')

    return "N/A"


#12. Function to get application links from the first page
"""Retrieve all application links from the main list page."""

def get_application_links_from_first_page(main_list_url):
    response = session.get(main_list_url, headers=headers)
    strainer = SoupStrainer('tr', class_=lambda x: x in ['row1', 'row0'])
    soup = BeautifulSoup(response.text, 'lxml', parse_only=strainer)
    links = soup.find_all('a', id="Anwendungen")
    first_page_links = {}

    for link in links:
        app_name = link.text.strip()
        trade_number = link['href'].split('=')[-1]
        unique_key = f"{app_name} {trade_number}"
        first_page_links[unique_key] = f"{base_url}{link['href']}"

    return first_page_links


#13. Function to parse main list page and get all application links of all pesticides starting from page 2 to 68
"""
The URLs differ for the first page, which initialises a new session, and the rest. Therefore, looping all pages by altering
page=1 to page=2 isn't easy. It's better to scrape the data separately.
"""
def get_application_links():
    all_links = {}

    # Start from page 2 as page 1 is handled separately by get_application_links_from_first_page()
    for page in range(2, 69):
        page_url = f"{base_url}ListeMain.jsp?page={page}"
        print(f"Fetching page {page}: {page_url}")  # Debugging print
        response = session.get(page_url, headers=headers)

        if response.status_code == 200:
            strainer = SoupStrainer('tr', class_=lambda x: x in ['row1', 'row0'])
            soup = BeautifulSoup(response.text, 'lxml', parse_only=strainer)
            links = soup.find_all('a', id="Anwendungen")
            print(f"Found {len(links)} links on page {page}")  # Debugging print
            
            for link in links:
                app_name = link.text.strip()
                trade_number = link['href'].split('=')[-1]  # Extract trade number from the URL
                unique_key = f"{app_name} {trade_number}"  # Combine name and trade number for a unique key
                all_links[unique_key] = f"{base_url}{link['href']}"
                # print(f"Added {unique_key}: {all_links[unique_key]}")  # Debugging print
        else:
            print(f"Failed to fetch page {page}, status code: {response.status_code}")

    return all_links


#14. Main function to coordinate the scraping process
def main_scraping_process():
    try:
        # Initialize the session and get the URL for the first page
        main_list_url = get_main_list_url()  # This gets the URL that starts the session and points to the first page
        print(f"URL for the first page: {main_list_url}")  # Debug print

        if not main_list_url:
            print("Failed to retrieve the main list URL.")
            return

        # Scrape data from the first page
        all_application_details = []
        first_page_links = get_application_links_from_first_page(main_list_url)  # Function to get links from the first page

        for app_name, app_url in first_page_links.items():
            detail_urls = get_application_details_urls(app_url)

            for detail_url in detail_urls:
                app_detail = scrape_application_details(detail_url)

                if app_detail:
                    all_application_details.append(app_detail)

        # Continue scraping from page 2 to 68
        subsequent_pages_links = get_application_links()  # Function to get links from page 2 to 67
        for app_name, app_url in subsequent_pages_links.items():
            detail_urls = get_application_details_urls(app_url)

            for detail_url in detail_urls:
                app_detail = scrape_application_details(detail_url)

                if app_detail:
                    all_application_details.append(app_detail)

        
        # Save all collected data to CSV
        df = pd.DataFrame(all_application_details)
        df.to_csv(f"{output_dir}/{output_file_name}", index=False)
        print("Scraping completed and data saved to CSV.")

    except Exception as e:
        print(f"An error occurred: {e}")


#15. Run the function
main_scraping_process()
