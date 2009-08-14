require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb')

describe "/plugin/bookmarks" do
  before(:each) do
    @response = request("/plugin/bookmarks")
  end
end