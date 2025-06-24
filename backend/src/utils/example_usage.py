#!/usr/bin/env python3
"""
Example usage of the LoggingManager
Demonstrates different ways to configure and use the centralized logging
"""

import os
from logging_manager import LoggingManager


def main():
    """Example main function showing logging usage"""
    
    # Configure logging based on environment
    debug_mode = os.getenv("DEBUG", "false").lower() == "true"
    log_level = os.getenv("LOG_LEVEL", "INFO")
    
    # Initialize logging
    LoggingManager.configure_logging(level=log_level, debug=debug_mode)
    
    # Get logger instances for different components
    main_logger = LoggingManager.get_logger("main")
    api_logger = LoggingManager.get_logger("api")
    db_logger = LoggingManager.get_logger("database")
    
    # Example usage
    main_logger.info("Application started")
    api_logger.info("API endpoint accessed: /users")
    db_logger.debug("Database query executed: SELECT * FROM users")
    
    # Example error logging
    try:
        # Simulate an error
        result = 1 / 0
    except ZeroDivisionError as e:
        main_logger.error(f"Division by zero error: {e}")
    
    # Add custom file handler
    LoggingManager.add_file_handler(
        "logs/custom.log",
        level="WARNING",
        rotation="5 MB",
        retention="14 days"
    )
    
    main_logger.warning("This will go to custom.log")
    main_logger.info("Application finished")


if __name__ == "__main__":
    main() 