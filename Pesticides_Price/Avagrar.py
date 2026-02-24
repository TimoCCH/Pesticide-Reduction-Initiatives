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
    "output_file": "../Pesticides_price/Avagrar.csv",
    "base_url": "https://avagrar.de/Pflanzenschutzmittel/?order=name-asc&p=",
    "max_pages": 22 # Users are recommended to check the maximum page before scraping
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


#5. Fetch HTML
def fetch_html(url):
    logging.info(f"Fetching URL: {url}")
    response = http.get(url)
    response.raise_for_status()
    return response.text


#6. Extract product data from a page
def extract_data_from_html(html):
    soup = BeautifulSoup(html, "lxml")
    products = soup.find_all("div", class_="product-info")

    logging.info(f"Found {len(products)} products on the page.")

    extracted = []
    for product in products:
        name_tag = product.find("a", class_="product-name")
        unit_tag = product.find("span", class_="price-unit-content")
        ref_tag = product.find("span", class_="price-unit-reference")
        price_tag = product.find("span", class_="product-price")

        product_name = name_tag.get("title", "N/A") if name_tag else "N/A"
        unit_content = unit_tag.get_text(strip=True) if unit_tag else "N/A"
        unit_reference = ref_tag.get_text(strip=True) if ref_tag else "N/A"
        product_price = price_tag.get_text(strip=True) if price_tag else "N/A"

        extracted.append({
            "Handelsbezeichnung": product_name,
            "Gebinde": unit_content,
            "Grundpreis": unit_reference,
            "Gebindepreis": product_price
        })

    return extracted


#7. Main scraping function
def main_scrape():
    all_data = []

    for page in range(1, CONFIG["max_pages"] + 1):
        url = CONFIG["base_url"] + str(page)
        html = fetch_html(url)
        page_data = extract_data_from_html(html)
        all_data.extend(page_data)
        logging.info(f"Page {page} completed: {len(page_data)} products scraped.")

    # Save to Excel
    logging.info("Saving data to Excel...")
    df = pd.DataFrame(all_data)
    output_csv = CONFIG["output_file"]
    df.to_csv(output_csv, index=False)
    
    logging.info(f"Data saved successfully to {output_csv}")

if __name__ == "__main__":
    main_scrape()
