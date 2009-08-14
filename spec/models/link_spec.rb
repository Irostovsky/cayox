require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Link do

  it "should be uniq in system" do
    Link.gen(:url => "http://apple.com")
    Link.new(:url => "http://apple.com").should_not be_valid
  end

  it "should validate" do
    # direct creation
    Link.new(:url => "http://jola.com").should be_valid
    Link.new(:url => "https://misio.com/jola").should be_valid
    Link.new(:url => "http://").should_not be_valid
    
    # indirect lookup
    Link.get_by_url("apple.com").should be_valid
    Link.get_by_url("jolka.com").should be_valid
    Link.get_by_url("12345").should_not be_valid
  end

  it "should have name same as url" do
    link = Link.make
    link.name.should == link.url
  end

  it "should set site and root for proper url" do
    link = Link.get_by_url("http://jolanta.rutowicz.com")
    link.save
    link.should be_root
    link.site.should == "jolanta.rutowicz.com"

    link = Link.get_by_url("http://jolanta.rutowicz.com/")
    link.should be_root
    link.site.should == "jolanta.rutowicz.com"

    link = Link.get_by_url("http://jolanta.rutowicz.com/kobieta_kon")
    link.save
    link.should_not be_root
    link.site.should == "jolanta.rutowicz.com"

    link = Link.get_by_url("https://jolanta.rutowicz.com/kobieta/kon/")
    link.save
    link.should_not be_root
    link.site.should == "jolanta.rutowicz.com"
  end

  it "shouldn't be valid if url has more than 512 chars" do
    link = Link.create(:url => "https://jolanta.rutowicz.com/kobieta" + ("/kon" * 200))
    link.should_not be_valid
    link.errors.on(:url).should_not be_empty
  end

  it "should treat foo.pl and foo.pl/ as the same link" do
    link = Link.get_by_url("foo.pl")
    link.save
    link.url.should == "http://foo.pl/"
    lambda do
      new_link = Link.get_by_url("foo.pl/")
      new_link.should == link
    end.should_not change(Link, :count)
  end

  it "should treat foo.pl/jola and foo.pl/jola/ as different links" do
    link = Link.get_by_url("foo.pl/jola")
    link.save
    link.url.should == "http://foo.pl/jola"
    lambda do
      new_link = Link.get_by_url("foo.pl/jola/")
      new_link.save
      new_link.should_not == link
    end.should change(Link, :count).by(1)
  end
end
