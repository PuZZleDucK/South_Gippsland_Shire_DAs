
require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

# Performed for each application found
def scrape_details(new_page, new_date)
# Pick out xpaths for data
  council_reference = new_page.at("/html/body/form/div/table[2]/tr/td/div/table[2]/tr[1]/td/div/table[2]/tr[3]/td[2]/*").text
  address = new_page.at("/html/body/form/div/table[2]/tr/td/div/table[2]/tr[1]/td/div/table[2]/tr[4]/td[2]/*").text
  type = new_page.at("/html/body/form/div/table[2]/tr/td/div/table[2]/tr[1]/td/div/table[2]/tr[1]/td[2]/*").text
  description = "#{new_page.at("/html/body/form/div/table[2]/tr/td/div/table[2]/tr[1]/td/div/table[2]/tr[2]/td[2]/*").text} (#{type})"
  info_url = new_page.at("/html/body/form/div/table[2]/tr/td/div/table[2]/tr[4]/td/div/table[2]/tr/td[2]/a").attribute("href").to_s

# prep dates
  date_received = new_date.to_s
  on_notice_from = new_date.to_s
  on_notice_to = (new_date+14).to_s
  
  record = {
    'council_reference' => council_reference,
    'address' => address,
    'description' => description,
    'info_url' => info_url,
    'date_received' => date_received,
    'on_notice_from' => on_notice_from,
    'on_notice_to' => on_notice_to,
    'date_scraped' => @date_scraped,
    'comment_url' => @comment_url,
  }
#  puts "\n :: RECORD :: \n#{record}"
  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    puts "Storing " + record['council_reference']
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Skipping already saved record " + record['council_reference']
  end
end

# Read in a page
page = agent.get("https://eservices.southgippsland.vic.gov.au/ePathway/ePathProd/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP")
@comment_url = "https://www.southgippsland.vic.gov.au/site/scripts/xforms_form.php?formID=193"
@date_scraped = Date.today.to_s

# Each EnquiryDetailView link is an application
page.links.each do |link|
  if link.href.to_s["EnquiryDetailView"]
    new_page = link.click
    new_date = Date.parse(link.node.parent.parent.next_sibling.next_sibling.next_sibling.text)
#    puts "date: #{date}"
    scrape_details(new_page, new_date)
  end
end