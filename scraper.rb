
require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

# Performed for each application found
def scrape_details(detail_page)
  info_url = 'https://eservices.southgippsland.vic.gov.au/ePathway/ePathProd/Web/GeneralEnquiry/EnquiryDetailView.aspx?Id='
# Pick out xpaths for data
  council_reference = detail_page.at('//div[@class="fields"]/div[@class="field"][3]/td').text
  address           = detail_page.at('//div[@class="fields"]/div[@class="field"][4]/td').text
  description       = detail_page.at('//div[@class="fields"]/div[@class="field"][2]/td').text
  info_url          = info_url << detail_page.at('//div[@id="ctl00_MainBodyContent_group_425"]/div[@class="fields"]/div[@class="field"]/td').text

  record = {
    'council_reference' => council_reference,
    'address' => address,
    'description' => description,
    'info_url' => info_url,
    'date_received' => @date_received,
    'date_scraped' => @date_scraped,
    'comment_url' => @comment_url,
  }

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    puts "Storing " + record['council_reference']
#    puts record
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
    detail_page = link.click
    @date_received = Date.parse(link.node.parent.parent.next_sibling.next_sibling.next_sibling.text).to_s
    scrape_details(detail_page)
  end
end
