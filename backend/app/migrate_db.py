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
            ('"user"', "share_chat_with_counselor", "BOOLEAN DEFAULT FALSE"),
        ]
        
        for table, col, col_type in columns_to_ensure:
            try:
                sql = f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {col} {col_type};"
                conn.execute(text(sql))
                logger.info(f"Ensured column {table}.{col}")
            except Exception as e:
                logger.warning(f"Note on {table}.{col}: {e}")

        # 3. Ensure B-tree performance indexes for high-concurrency queries
        indexes_to_ensure = [
            ("ix_moodentry_user_id", "moodentry", "user_id"),
            ("ix_moodentry_created_at", "moodentry", "created_at"),
            ("ix_chatsession_user_id", "chatsession", "user_id"),
            ("ix_chatsession_created_at", "chatsession", "created_at"),
            ("ix_chatmessage_session_id", "chatmessage", "session_id"),
            ("ix_chatmessage_created_at", "chatmessage", "created_at"),
            ("ix_chatmessage_risk_flag", "chatmessage", "risk_flag"),
            ("ix_notification_created_at", "notification", "created_at"),
            ("ix_notification_is_read", "notification", "is_read"),
            ("ix_notification_is_deleted", "notification", "is_deleted"),
            ("ix_journalentry_created_at", "journalentry", "created_at"),
            ("ix_user_created_at", '"user"', "created_at"),
        ]

        for idx_name, table, col in indexes_to_ensure:
            try:
                sql = f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table} ({col});"
                conn.execute(text(sql))
                logger.info(f"Ensured index {idx_name} on {table}({col})")
            except Exception as e:
                logger.warning(f"Note on index {idx_name}: {e}")
                
        conn.commit()
        logger.info("Database migration successfully completed!")

if __name__ == "__main__":
    migrate()
