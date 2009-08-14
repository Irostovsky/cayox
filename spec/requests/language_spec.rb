require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "UI translations" do
  before(:all) do
    @polish = Language.create(:iso_code => "pl", :name => "Polish")
    @german = Language.create(:iso_code => "de", :name => "German")
    @russian = Language.create(:iso_code => "ru", :name => "Russian")
  end

  describe "for guest" do

    it "should show homepage in english when language isn't set anywhere" do
      response = request("/")
      response.should have_selector("#top:contains('Join')")
    end

    it "should show homepage in polish when language is set only in browser" do
      ['pl', 'pl-PL', 'pl_PL'].each do |lang|
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => lang)
        response.should have_selector("#top:contains('Zaloguj')")
      end
    end

    it "should show homepage in english when language set in browser is non-gui language" do
      ['it', 'sp', 'ru'].each do |lang|
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => lang)
        response.should have_selector("#top:contains('Join')")
      end
    end

  end

  describe "for registered user" do

    it "should show homepage in english when language isn't set anywhere" do
      as(User.gen(:primary_language => nil)) do
        response = request("/")
        response.should have_selector("#top:contains('Welcome')")
      end
    end

    it "should show homepage in polish when language is set only in browser" do
      as(User.gen(:primary_language => nil)) do
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => 'pl')
        response.should have_selector("#top:contains('Witaj')")
      end
    end

    it "should show homepage in polish when language is set only in profile" do
      as(User.gen(:primary_language => @polish)) do
        response = request("/")
        response.should have_selector("#top:contains('Witaj')")
      end
    end

    it "should show homepage in german when language is set to german in profile and to polish in browser" do
      as(User.gen(:primary_language => @german)) do
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => 'pl')
        response.should have_selector("#top:contains('Willkommen')")
      end
    end

    it "should show homepage in polish when language is set to russian in profile and to polish in browser" do
      as(User.gen(:primary_language => @russian)) do
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => 'pl')
        response.should have_selector("#top:contains('Witaj')")
      end
    end

    it "should show homepage in english when language is set to russian in profile and to japanesse in browser" do
      as(User.gen(:primary_language => @russian)) do
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => 'jp')
        response.should have_selector("#top:contains('Welcome')")
      end
    end

    it "should show homepage in polish when primary language in profile is set to russian, secondary is set to polish and browser language to japanesse" do
      user = User.gen(:primary_language => @russian)
      user.user_languages << UserLanguage.new(:language => @polish)
      user.save
      as(user) do
        response = request("/", 'HTTP_ACCEPT_LANGUAGE' => 'jp')
        response.should have_selector("#top:contains('Witaj')")
      end
    end
  end

end

describe "Topic translations" do
end

describe "Element translations" do
end
