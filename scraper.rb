require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'uri'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL of the page
url = 'https://www.bodc.tas.gov.au/council/advertised-development-applications/'

# Step 1: Fetch the iframe content using open-uri
begin
  logger.info("Fetching content from: #{url}")
  url = open(url).read
  logger.info("Successfully fetched content.")
rescue => e
  logger.error("Failed to fetch content: #{e}")
  exit
end

# Step 2: Parse the iframe content using Nokogiri
doc = Nokogiri::HTML(url)

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create the table if it doesn't exist
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS breakoday (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_scraped TEXT,
    date_received TEXT,
    on_notice_to TEXT,
    address TEXT,
    council_reference TEXT,
    applicant TEXT,
    owner TEXT,
    stage_description TEXT,
    stage_status TEXT,
    document_description TEXT
  );
SQL

# Define variables for storing extracted data for each entry
address = ''  
description = ''
on_notice_to = ''
date_received = ''
council_reference = ''
applicant = ''
owner = ''
stage_description = ''
stage_status = ''
document_description = ''
date_scraped = ''


# Step 4: Iterate through each application block and extract the data
doc.css('div.card-body').each do |application|
  # Extract data from the rows in the table
  application_details = {}
  
  # Extract the table
  table = application.at_css('table.table')
  
  if table
    table.css('tbody tr').each do |row|
      # Extract the label (the first column) and value (the second column)
      label = row.at_css('td:nth-child(1)').text.strip
      value = row.at_css('td:nth-child(2)').text.strip

      # Log the extracted label and value
      logger.info("Row Label: #{label}, Value: #{value}")

      # Store the data in the application_details hash
      application_details[label] = value
    end

    # Log the full extracted data for debugging
    logger.info("Full Application Details: #{application_details}")

    # Step 6: Ensure the entry does not already exist before inserting
    existing_entry = db.execute("SELECT * FROM breakoday WHERE council_reference = ?", [council_reference])

    if existing_entry.empty? # Only insert if the entry doesn't already exist
      # Insert the data into the database
      db.execute("INSERT INTO breakoday (description, address, on_notice_to, document_description, council_reference, date_scraped) VALUES (?, ?, ?, ?, ?, ?)",
               [description, address, on_notice_to, document_description, council_reference, date_scraped])
      logger.info("Data for application #{council_reference} saved to database.")
    else
      logger.info("Duplicate entry for application #{council_reference} found. Skipping insertion.")
    end
  end
end

puts "Data has been successfully inserted into the database."
