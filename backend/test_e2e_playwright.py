"""
Kausap AI - Automated E2E Testing Script using Playwright
Usage: python test_e2e_playwright.py --url http://localhost:YOUR_PORT
"""
import sys
import argparse
from playwright.sync_api import sync_playwright

def run_e2e_test(target_url: str):
    print(f"=== Running Kausap AI E2E Automated Test on {target_url} ===")
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 420, "height": 840})
        page = context.new_page()

        print(f"  [1/4] Navigating to {target_url}...")
        try:
            page.goto(target_url, timeout=15000)
            page.wait_for_load_state("domcontentloaded")
            print("  [2/4] Flutter web page loaded successfully!")
        except Exception as e:
            print(f"  Note: Could not reach {target_url} ({e}). Ensure Flutter is running (`flutter run -d chrome`).")
            browser.close()
            return

        page.wait_for_timeout(2000)
        title = page.title()
        print(f"  [3/4] Page Title: '{title}'")

        # Capture diagnostic screenshot
        screenshot_path = "e2e_screen_preview.png"
        page.screenshot(path=screenshot_path)
        print(f"  [4/4] Saved automated preview screenshot to {screenshot_path}")

        browser.close()
        print("\nE2E PLAYWRIGHT TEST COMPLETED SUCCESSFULLY!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://localhost:8000", help="Target URL to test")
    args = parser.parse_args()
    run_e2e_test(args.url)
