import logging
import signal
import sys
import time

from app.db.session import SessionLocal
from app.services.search.worker import EmbeddingWorker

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("embedding_worker")

running = True


def handle_shutdown(signum, frame):
    global running
    logger.info("Shutdown signal received (%d). Finishing current iteration...", signum)
    running = False


signal.signal(signal.SIGINT, handle_shutdown)
signal.signal(signal.SIGTERM, handle_shutdown)


def main():
    logger.info("BoardBuddy Embedding Outbox Worker started.")
    while running:
        db = SessionLocal()
        try:
            worker = EmbeddingWorker(db)
            processed = worker.process_outbox_jobs(limit=32)
            if processed > 0:
                logger.info("Processed %d embedding outbox jobs.", processed)
            else:
                time.sleep(3)
        except Exception as exc:
            logger.exception("Error in worker polling loop: %s", exc)
            time.sleep(5)
        finally:
            db.close()

    logger.info("Embedding Outbox Worker exited cleanly.")


if __name__ == "__main__":
    main()
