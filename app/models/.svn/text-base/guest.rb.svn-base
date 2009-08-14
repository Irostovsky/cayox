
class Guest
  def guest?
    true
  end

  def admin?
    false
  end
  
  def friends
    []
  end
  
  def friendships
    []
  end
  
  def pending_friendships
    []
  end
  
  def requested_friendships
    []
  end

  def primary_language
    nil
  end

  def secondary_languages
    []
  end

  def topics
    []
  end

  def all_topics
    []
  end

  def owned_topics
    []
  end

  def maintained_topics
    []
  end

  def favourite_elements
    []
  end

  def search_results_per_page
    Cayox::CONFIG[:search_results_per_page]
  end
  
  def elements_per_page
    Cayox::CONFIG[:elements_per_page]
  end

  def preferred_content_language(content, default_lang)
    iso_code = (content.keys & [default_lang]).first
    iso_code ||= (content.keys & [Cayox::CONFIG[:fallback_language_code]]).first
    iso_code ||= content.keys.first
    iso_code
  end
end