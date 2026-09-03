import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker


load_dotenv()


DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in the .env file")

engine = create_engine(DATABASE_URL)

engine = create_engine(DATABASE_URL)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


Base = declarative_base()


def test_database_connection():

    try:

        with engine.connect() as connection:

            result = connection.execute(
                text("SELECT 1")
            )

            print("Database connected successfully!")

            print(
                "Result:",
                result.scalar()
            )

    except Exception as e:

        print("Database connection failed!")

        print(e)


if __name__ == "__main__":
    test_database_connection()