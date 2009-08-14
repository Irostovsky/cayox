require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LinkLanguage do

  it "should add missing link_languages for specified links and language" do
    lang = Language.gen
    links = [Link.gen, Link.gen, Link.gen, Link.gen]

    links.each do |link|
      link.reload
      link.languages.should be_empty
    end

    lambda { LinkLanguage.add_missing_link_languages(links, lang) }.should change(LinkLanguage, :count).by(links.size)

    links.each do |link|
      link.reload
      link.languages.should_not be_empty
    end
  end

  it "shouldn't add link_languages for links which already contains them" do
    lang = Language.gen
    link = Link.gen
    lambda { LinkLanguage.add_missing_link_languages([link], lang) }.should change(LinkLanguage, :count).by(1)
    link.reload
    lambda { LinkLanguage.add_missing_link_languages([link], lang) }.should_not change(LinkLanguage, :count)
  end
end