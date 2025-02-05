require 'nokogiri'
require 'open-uri'
require 'sqlite3'

# Initialize the SQLite database
db = SQLite3::Database.new "development_applications.db"

# Create the table if it doesn't exist
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS breakoday (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_received TEXT,
    address TEXT,
    council_reference TEXT,
    applicant TEXT,
    owner TEXT,
    stage_description TEXT,
    stage_status TEXT,
    document_description TEXT
  );
SQL

# Define the URL of the page
url = 'https://www.bodc.tas.gov.au/council/advertised-development-applications/'

# Fetch and parse the HTML content
html = URI.open(url)
doc = Nokogiri::HTML(html)

# Define variables for storing extracted data for each entry
address = ''  
description = ''
date_received = ''
council_reference = ''
applicant = ''
owner = ''
stage_description = ''
stage_status = ''
document_description = ''


# Find the table containing the development applications
table = doc.at_css('table') # Adjust the selector as needed

# Iterate through each row in the table
table.css('tr').each do |row|
  # Extract the columns
  columns = row.css('td')
  next if columns.empty? # Skip rows without data

  # Extract the text content of each column
  name = columns[0].text.strip
  address = columns[1].text.strip
  closing_date = columns[2].text.strip
  pdf_link = columns[3].css('a').first['href'] rescue nil

  # Insert the data into the database
  db.execute("INSERT INTO applications (name, address, closing_date, document_description) VALUES (?, ?, ?, ?)",
             [name, address, closing_date, pdf_link])
end

puts "Data has been successfully inserted into the database."
