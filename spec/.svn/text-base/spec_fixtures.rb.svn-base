def random_date(start_date, end_date)
  start_date + (rand * (end_date - start_date)).to_i
end

include DataMapper::Sweatshop::Unique

User.fixture {{
  :name => (name = unique { /\w{4,20}/.gen }),
  :full_name => "#{name.capitalize}'s Full Name",
  :email => "#{name}@kiszonka.com",
  :password => (password = /\w{6,20}/.gen), 
  :password_confirmation => password,
  :activated_at => 1.day.ago,
  :primary_language => (0..1).of { Language.gen }[0],
}}

User.fixture(:inactive) {{
  :name => (name = unique { /\w{6,20}/.gen }),
  :full_name => "#{name.capitalize}'s Full Name",
  :email => "#{name}@kiszonka.com",
  :password => (password = /\w{6,20}/.gen),
  :password_confirmation => password
}}

Link.fixture {{
  :site => (site = "http://#{ /\w{6,20}/.gen }.#{ /\w{2,4}/.gen }" ),
  :url =>  "#{site}/#{unique {/\w{6,20}/.gen }}",
  :is_root => false
}}

Bookmark.fixture {{
  :name => (name = unique { /\w{6,20}/.gen }),
  :description => "This is #{ /\w{6,20}/.gen } description ",
  :link => Link.gen,
  :user => User.gen
}}

Topic.fixture {{
  :name => { "pl" => (name = unique { /\w{6,20}/.gen }) },
  :description => { "pl" => "Opis #{name}" },
}}

Language.fixture {{
  :iso_code => ["en", "ru", "sp", "jp"][rand(4)],
  :name => /\w{6,20}/.gen
}}

Element.fixture {{
  :name => { :pl => (name = unique { /\w{6,20}/.gen }) },
  :description => { :pl => "This is #{name}'s description" },
  :link => Link.gen,
  :tag_list => ((0..5).of { /\w{3,8}/.gen }).join(",")
}}

ElementVote.fixture {{
  :user => User.gen,
  :element => Element.gen
}}

Tag.fixture {{
  :name => unique { /\w{3,16}/.gen }
}}

Flag.fixture {{
  :type => :topic,
  :description => unique { /\w{10,20}/.gen }
}}
