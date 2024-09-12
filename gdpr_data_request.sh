#!/bin/bash

# User ID to search for (can be passed as an argument to the script)
USER_ID="$1"

# Directory to search logs/files (change this based on your setup)
LOG_DIR="/var/logs/user_data"
OUTPUT_DIR="./gdpr_reports"

# Database connection details
DB_HOST="localhost"
DB_NAME="user_db"
DB_USER="root"
DB_PASSWORD="password"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Log files to search for user data
LOG_FILES=$(find "$LOG_DIR" -type f -name "*.log")

# Function to fetch user data from log files
fetch_user_data_from_files() {
    echo "Fetching user data from log files..."
    for log_file in $LOG_FILES; do
        echo "Searching in $log_file"
        grep "$USER_ID" "$log_file" >> "$OUTPUT_DIR/user_data_${USER_ID}.txt"
    done
}

# Function to fetch user data from the database
fetch_user_data_from_db() {
    echo "Fetching user data from the database..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
    SELECT * FROM users WHERE user_id = '$USER_ID';
    " > "$OUTPUT_DIR/user_data_db_${USER_ID}.csv"
}

# Function to generate reports
generate_report() {
    echo "Generating report for user $USER_ID..."
    echo "Log Data Report:"
    cat "$OUTPUT_DIR/user_data_${USER_ID}.txt"

    echo "Database Report:"
    cat "$OUTPUT_DIR/user_data_db_${USER_ID}.csv"
}

# Function to securely delete user data (for the right to be forgotten)
delete_user_data() {
    echo "Securely deleting user data from logs and database..."

    # Delete from log files (overwrite with shred)
    for log_file in $LOG_FILES; do
        grep -l "$USER_ID" "$log_file" | xargs -I{} shred -u {}
    done

    # Delete from database
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
    DELETE FROM users WHERE user_id = '$USER_ID';
    "
    
    echo "User data deletion completed for $USER_ID."
}

# Main script logic
if [ -z "$USER_ID" ]; then
    echo "Usage: $0 <user_id>"
    exit 1
fi

fetch_user_data_from_files
fetch_user_data_from_db
generate_report

# Prompt for deletion of data
read -p "Do you want to delete user data for $USER_ID? (y/n): " confirm
if [[ "$confirm" == "y" ]]; then
    delete_user_data
else
    echo "User data was not deleted."
fi

echo "GDPR Data Request process completed for user: $USER_ID."
