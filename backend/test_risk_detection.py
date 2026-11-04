"""
test_risk_detection.py
----------------------
Verifies the multilingual (English / Tagalog / Bisaya) crisis keyword interceptor.
Run:  python test_risk_detection.py
"""

import sys

from app.core.risk_detection import check_for_risk

errors = []


def check(condition, msg):
    if condition:
        print(f"  PASS: {msg}")
    else:
        print(f"  FAIL: {msg}")
        errors.append(msg)


print("=== English crisis phrases ===")
for text in [
    "I want to die",
    "I'm thinking about suicide",
    "everything feels hopeless",
    "I might hurt myself tonight",
]:
    check(check_for_risk(text), f"flagged: {text!r}")

print("\n=== Tagalog crisis phrases ===")
for text in [
    "Gusto ko mamatay",
    "gusto ko na mamatay",
    "Mamatay na lang ako",
    "iniisip kong magpakamatay",
    "Ayoko na mabuhay",
    "wala nang pag-asa",
    "Wala nang pagasa",
    "Di ko na kaya",
    "sasaktan ko ang sarili ko",
]:
    check(check_for_risk(text), f"flagged: {text!r}")

print("\n=== Bisaya crisis phrases ===")
for text in [
    "gusto nako mamatay",
    "gusto na ko mamatay",
    "Maghikog na ko",
    "naghunahuna ko og hikog",
    "mamatay na lang ko",
    "kapoy na mabuhi",
    "kapoy na kaayo mabuhi",
    "Di na nako kaya",
    "dili na nako kaya",
    "wala na koy paglaum",
]:
    check(check_for_risk(text), f"flagged: {text!r}")

print("\n=== Safe messages must NOT be flagged ===")
for text in [
    "I feel stressed about my thesis defense",
    "Kumusta ka? Pagod ako ngayon pero okay lang",
    "Masaya ako ngayon, salamat",
    "Nakakapagod ang exam week, kaya ko ito",
    "Maayo ra ko karon, salamat",
    "Naa koy exam ugma, kulbaan ko",
    "",
]:
    check(not check_for_risk(text), f"not flagged: {text!r}")

print()
if errors:
    print(f"RESULT: {len(errors)} check(s) FAILED")
    sys.exit(1)
print("RESULT: ALL CHECKS PASSED")
