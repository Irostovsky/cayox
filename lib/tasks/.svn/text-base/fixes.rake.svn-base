namespace :cayox do
  namespace :fix do

    desc "Fix topics without creator"
    task :set_topics_creators => :merb_env do
      Topic.all.select { |t| t.creator.nil? }.each { |t| t.creator = t.owners.first; t.save }
    end

    desc "Fix links at domain root which are missing trailing slash"
    task :links_at_domain_root => :merb_env do
      links_to_fix = Link.all(:is_root => true).select { |l| l.url =~ /^\w+:\/\/[^\/]+$/ }
      n = links_to_fix.size
      links_to_fix.each do |link|
        
        new_link = Link.get_by_url(link.url)
        new_link.save

        Element.all(:link_id => link.id).each do |element|
          element.link = new_link
          element.save
          element.destroy unless element.valid?
        end

        Bookmark.all(:link_id => link.id).each do |bookmark|
          bookmark.link = new_link
          bookmark.save
          bookmark.destroy unless bookmark.valid?
        end

        LinkLanguage.all(:link_id => link.id).each do |ll|
          ll.link = new_link
          ll.save
        end

        link.destroy
      end
      puts "Fixed #{n} links"
    end

    desc "Fix tags' names converting them to lowercase"
    task :tags_case => :merb_env do
      Tag.all.each { |t| t.name = t.name.downcase; t.save }
    end
      
  end
end