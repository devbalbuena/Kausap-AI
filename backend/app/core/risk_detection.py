import re

# Simple keyword matching for crisis detection
# This is a basic implementation that can be expanded later or replaced with ML models
CRISIS_KEYWORDS = [
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

def check_for_risk(text: str) -> bool:
    """
    Checks if the given text contains any crisis-related keywords.
    Returns True if risk is detected, False otherwise.
    """
    text_lower = text.lower()
    for pattern in CRISIS_KEYWORDS:
        if re.search(pattern, text_lower):
            return True
    return False
