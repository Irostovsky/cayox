require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Language do

  it "should be created from fixture" do
    Language.gen.should be_valid
  end

  it "should be lookup with [] operator" do
    ["pl", "en", "de", "fr", "sp", "jp"].each { |code| Language.gen(:iso_code => code) }

    Language["jp"].should == Language.first(:iso_code => "jp")
    ["pl", "en", "de", "fr", "sp", "jp"].each { |code| Language[code].should == Language.first(:iso_code => code) }
  end

end