from sqlmodel import Session, create_engine, text
from app.core.config import settings
from dotenv import load_dotenv

load_dotenv()

engine = create_engine(settings.DATABASE_URL, echo=True)

def migrate():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE moodentry ADD COLUMN emotions VARCHAR;"))
            print("Added emotions column.")
        except Exception as e:
            print(f"Emotions column might already exist: {e}")
            
        try:
            conn.execute(text("ALTER TABLE moodentry ADD COLUMN intensity INTEGER;"))
            print("Added intensity column.")
        except Exception as e:
            print(f"Intensity column might already exist: {e}")
        
        conn.commit()

if __name__ == "__main__":
    migrate()
