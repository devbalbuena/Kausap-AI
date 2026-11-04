import re

# Simple keyword matching for crisis detection
# This is a basic implementation that can be expanded later or replaced with ML models

# English crisis phrases
_ENGLISH_CRISIS_KEYWORDS = [
    r"\bsuicide\b",
    r"\bkill myself\b",
    r"\bwant to die\b",
    r"\bend it all\b",
    r"\bno reason to live\b",
    r"\bbetter off dead\b",
    r"\bhurt myself\b",
    r"\bcut myself\b",
    r"\bharm myself\b",
    r"\bgive up\b",
    r"\bhopeless\b"
]

# Tagalog crisis phrases (Filipino students often express distress in their mother tongue)
_TAGALOG_CRISIS_KEYWORDS = [
    r"\bgusto ko (na )?mamatay\b",
    r"\bmamatay na (lang )?ako\b",
    r"\bmagpakamatay\b",
    r"\bpapatayin ko (na )?(ang )?sarili ko\b",
    r"\bayoko na (po )?mabuhay\b",
    r"\bayaw ko na (po )?mabuhay\b",
    r"\bwala nang pag-?asa\b",
    r"\bwala na akong pag-?asa\b",
    r"\bsasaktan ko (ang )?sarili ko\b",
]

# Bisaya / Cebuano crisis phrases (common in Caraga / Butuan City)
_BISAYA_CRISIS_KEYWORDS = [
    r"\bhikog\b",
    r"\bmaghikog\b",
    r"\bgusto (na ?)?ko mamatay\b",
    r"\bmamatay na lang ko\b",
    r"\bdili na ko gusto mabuhi\b",
    r"\bayaw na ko mabuhi\b",
    r"\bkapoy na (kaayo )?mabuhi\b",
    r"\bdi(li)? na (na|a)?ko kaya\b",
    r"\bdi(li)? ko na kaya\b",
    r"\bwala na koy paglaum\b",
]

CRISIS_KEYWORDS = _ENGLISH_CRISIS_KEYWORDS + _TAGALOG_CRISIS_KEYWORDS + _BISAYA_CRISIS_KEYWORDS

_COMPILED_CRISIS_PATTERNS = [re.compile(p, re.IGNORECASE) for p in CRISIS_KEYWORDS]


def check_for_risk(text: str) -> bool:
    """
    Checks if the given text contains any crisis-related keywords
    (English, Tagalog, or Bisaya).
    Returns True if risk is detected, False otherwise.
    """
    text_lower = text.lower()
    for pattern in _COMPILED_CRISIS_PATTERNS:
        if pattern.search(text_lower):
            return True
    return False
