#1. Import necessary libraries
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import pandas as pd
import time
import logging


#2. Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


#3. Configuration
CONFIG = {
    "base_url": "https://www.myagrar.de/pflanzenschutzmittel/?page={page}&sort=Name%3Aasc&name=Name&order=asc",
    "output_file": "../Pesticides_price/Myagrar.csv",
    "max_pages": 30 # Users are recommended to check the maximum page before scraping
}


#4. Setup Selenium
options = Options()
# options.add_argument("--headless")  # Uncomment for headless mode
driver = webdriver.Chrome(options=options)
wait = WebDriverWait(driver, 10)

all_data = []

for page in range(1, CONFIG["max_pages"] + 1):
    url = CONFIG["base_url"].format(page=page)
    driver.get(url)
    logging.info(f"🌐 Visiting page {page}")
    time.sleep(5)


    # Dismiss cookie banner once
    if page == 1:
        try:
            dismissed = False
            for iframe in driver.find_elements(By.TAG_NAME, "iframe"):
                driver.switch_to.frame(iframe)
                try:
                    cookie_button = WebDriverWait(driver, 2).until(
                        EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Nur notwendige Cookies')]"))
                    )
                    cookie_button.click()
                    driver.switch_to.default_content()
                    logging.info("✅ Cookie banner dismissed via iframe.")
                    dismissed = True
                    break
                except:
                    driver.switch_to.default_content()

            if not dismissed:
                cookie_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Nur notwendige Cookies')]")
                cookie_button.click()
                logging.info("✅ Cookie banner dismissed on main page.")
        except Exception as e:
            logging.warning(f"⚠️ Could not dismiss cookie banner: {e}")

    try:
        wait.until(EC.presence_of_element_located((By.XPATH, "//a[contains(@class, 'product-item-link')]")))
    except Exception:
        logging.error(f"❌ Product list did not load on page {page}")
        continue

    products = driver.find_elements(By.XPATH, "//div[contains(@class, 'product-item-info')]")
    logging.info(f"🔍 Found {len(products)} products on page {page}")

    for product in products:
        try:
            name = product.find_element(By.XPATH, ".//a[contains(@class, 'product-item-link')]").text.strip()

            unit_price_el = product.find_elements(By.XPATH, ".//span[contains(@class, 'js-product-')]")
            unit_price = unit_price_el[0].text.strip() if unit_price_el else ""

            package_price_el = product.find_elements(By.XPATH, ".//div[contains(@class, 'product-item__details__final-price')]")
            package_price = package_price_el[0].text.strip() if package_price_el else ""

            all_data.append({
                "Handelsbezeichnung": name,
                "Grundpreis": unit_price,
                "Gebindepreis": package_price
            })
            logging.info(f"✅ {name} | {unit_price} | {package_price}")
        except Exception as e:
            logging.warning(f"⚠️ Skipped a product due to error: {e}")

# Save to Excel
driver.quit()
df = pd.DataFrame(all_data)
df.to_csv(CONFIG["output_file"], index=False)
logging.info(f"✅ All {len(all_data)} products saved to: {CONFIG['output_file']}")
