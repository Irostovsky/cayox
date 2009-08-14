
xss_terminator_regex = /<[\w\/][^>]*\/?>/

DataMapper::Resource.descendants.reject { |d| d.name.to_s =~ /Merb::/ || d <= Notification }.each do |model| # install before validate hook into all our models
  model.class_eval do
    before :valid? do
      self.class.properties.select { |p| p.primitive == DataMapper::Types::Text || p.primitive == String }.each do |prop| # choose only text and string properties
        value = self.send(prop.name)
        case value
        when String
          value.gsub!(xss_terminator_regex, '')
        when Hash, Mash
          value.keys.each do |key|
            value[key].gsub!(xss_terminator_regex, '') unless value[key].nil?
          end
        end
      end
    end
  end
end
