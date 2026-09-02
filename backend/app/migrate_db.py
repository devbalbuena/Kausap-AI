import logging
from sqlalchemy import text
from app.database import engine, SQLModel

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def migrate():
    # 1. First ensure all tables are created
    SQLModel.metadata.create_all(engine)
    
    # 2. Add any missing columns to existing tables safely
    with engine.connect() as conn:
        columns_to_ensure = [
            ("article", "status", "VARCHAR DEFAULT 'published'"),
            ("article", "is_featured", "BOOLEAN DEFAULT FALSE"),
            ("article", "view_count", "INTEGER DEFAULT 0"),
            ("article", "share_count", "INTEGER DEFAULT 0"),
            ("article", "ai_discussion_count", "INTEGER DEFAULT 0"),
            ("article", "reaction_counts_json", "TEXT DEFAULT '{}'"),
            ("article", "theme_color_hex", "VARCHAR DEFAULT '#0284C7'"),
            ("article", "content_json", "TEXT DEFAULT '[]'"),
            ("article", "is_published", "BOOLEAN DEFAULT TRUE"),
        ]
        
        for table, col, col_type in columns_to_ensure:
            try:
                sql = f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {col} {col_type};"
                conn.execute(text(sql))
                logger.info(f"Ensured column {table}.{col}")
            except Exception as e:
                logger.warning(f"Note on {table}.{col}: {e}")
                
        conn.commit()
        logger.info("Database migration successfully completed!")

if __name__ == "__main__":
    migrate()
