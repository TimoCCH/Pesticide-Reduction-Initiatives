#1. Import necessary libraries
import requests
from bs4 import BeautifulSoup
import pandas as pd
import logging
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


#2. Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


#3. Configuration
CONFIG = {
    "output_file": "../Pesticides_Price/Baywa.csv",
    "base_url_no_param": "https://www.baywa.de/de/pflanzenbau/pflanzenschutzmittel/c-sh_bp_9425899/?q=%3Aname-asc",
    "max_pages": 19 # Users are recommended to check the maximum page before scraping
}


#4. Retry logic for requests
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


#5. Fetches and parses the HTML from the given URL
def fetch_html(url):
    logging.info(f"Fetching URL: {url}")
    resp = http.get(url)
    resp.raise_for_status()
    return resp.text


#6. Function to extract product data
def extract_data_from_html(html):
    soup = BeautifulSoup(html, "lxml")
    tiles = soup.select("div.product-tile")

    extracted = []
    for tile in tiles:
        name = tile.select_one("div.product-tile__link.title.h4")
        preis = tile.select_one("div.price .h3")
        grundpreis = tile.select_one("div.baseprice")

        # Gebinde info inside table
        gebinde = "N/A"
        table = tile.select_one("div.details table")
        if table:
            for tr in table.select("tr"):
                tds = tr.select("td")
                if len(tds) == 2 and "Gebinde" in tds[0].text:
                    gebinde = tds[1].text.strip()

        extracted.append({
            "Handelsbezeichnung": name.get_text(strip=True) if name else "N/A",
            "Gebinde": gebinde,
            "Grundpreis": grundpreis.get_text(strip=True) if grundpreis else "N/A",
            "Gebinde_info": preis.get_text(strip=True) if preis else "N/A"
        })
    return extracted


#7. Main scraping initialization
def main_scrape():
    all_data = []

    # 1) Scrape the first page (no page param)
    html = fetch_html(CONFIG["base_url_no_param"])
    page_data = extract_data_from_html(html)
    all_data.extend(page_data)
    logging.info(f"Page 0: {len(page_data)} products.")

    # 2) Then scrape pages 1..(max_pages-1) to handle the offset
    # If max_pages=19, that means page=18 is the last. 
    # i.e., page=1 => second page, page=18 => 19th page.
    for page in range(1, CONFIG["max_pages"]):
        url = f"{CONFIG['base_url_no_param']}&page={page}"
        html = fetch_html(url)
        page_data = extract_data_from_html(html)
        all_data.extend(page_data)
        logging.info(f"Page {page}: {len(page_data)} products.")

    # Save the data
    df = pd.DataFrame(all_data)    
    output_csv = CONFIG["output_file"]
    df.to_csv(output_csv, index=False)

    logging.info(f"Data saved successfully to {output_csv}.")

if __name__ == "__main__":
    main_scrape()