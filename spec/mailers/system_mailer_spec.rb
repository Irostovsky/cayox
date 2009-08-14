require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe SystemMailer do
  include MailControllerTestHelper
  
  before :each do
    clear_mail_deliveries
  end

  it "should include hello, specified body and footer" do
    user = User.gen
    body = "this is body\neven multiline\nand one more line"
    deliver :system_event, {}, :user => user, :body => body
    last_delivered_mail.text.should include("Hello")
    last_delivered_mail.text.should include(user.full_name)
    last_delivered_mail.text.should include(body)
    last_delivered_mail.text.should include("Cayox")
    last_delivered_mail.text.should include(Cayox::CONFIG[:site_url])
  end
   
end
