[Topic, Element, Bookmark, Favourite].each do |model|
  join_model = eval("#{model}Tag")
  relation_name = :"#{model.to_s.downcase}_tags"

  model.class_eval do
    property :frozen_tag_list, DataMapper::Types::Text, :lazy => false
    property :tag_count,       Integer

    has n, relation_name
    has n, :tags, :through => relation_name

    before :create, :update_tags
    before :update, :update_tags

    before :destroy do
      self.send(relation_name).destroy!
    end

    validates_with_block :tag_list do
      if invalid_tag = self.tag_list.detect { |t| t.size > 50 }
        [false, GetText._("Tag '%s' is too long (max 50 chars)") % invalid_tag.truncate(20)]
      elsif self.tag_list.join(",").size > 1024
        [false, GetText._("Tag list must be less than 1024 characters long")]
      else
        true
      end
    end

    def tag_list
      @tag_list ||= tags.map { |tag| tag.name }
    end

    def tag_list=(string)
      @tag_list = string.to_s.split(',').map { |name| name.gsub(/[^\.\w\s_-]/i, '').strip.downcase }.reject { |t| t.empty? }.uniq.sort
    end

    define_method(:update_tags) do

      Tag.all(:name => frozen_tag_list.to_s.split(',') - tag_list).each do |tag|
        if tagging = join_model.first(:"#{model.to_s.downcase}_id" => self.id, :tag_id => tag.id)
          tagging.destroy
        end
      end

      relation = self.send(relation_name)
      relation.reload
      tags.reload

      tag_list.each do |name|
        tag = Tag.first(:name => name)
        next if tag && tags.include?(tag)
        tag ||= Tag.create(:name => name)
        relation << join_model.new(:tag => tag) if tag.valid? # add TopicTag, ElementTag, BookmarkTag etc
      end

      self.frozen_tag_list = tag_list.join(',')
      self.tag_count = tag_list.size
    end
  end
end
