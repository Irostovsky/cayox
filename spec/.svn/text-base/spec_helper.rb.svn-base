require "rubygems"

ENV['LC_ALL'] = ENV['LC_LANG'] = "C"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "spec" # Satisfies Autotest and anyone else not using the Rake tasks

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:testing => true, :adapter => 'runner', :environment => ENV['MERB_ENV'] || 'test')

Merb::Mailer.delivery_method = :test_send

require Merb.root / "spec/spec_fixtures"
require Merb.root / "spec/fixtures_helper"
require Merb.root / "spec/cayox_controller_helper"
require Merb.root / "spec/cayox_matchers"
require Merb.root / "spec/mail_controller_specs_helper"

DataMapper.auto_migrate!
Language.gen(:iso_code => "en")
Language.gen(:iso_code => "pl")

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
  config.include(Cayox::Test::ControllerHelper)
  config.include(Cayox::Test::Matchers)

  config.after(:each) do
    repository(:default) do
      while repository.adapter.current_transaction
        repository.adapter.current_transaction.rollback
        repository.adapter.pop_transaction
      end
    end
  end

  config.before(:each) do
    repository(:default) do
      transaction = DataMapper::Transaction.new(repository)
      transaction.begin
      repository.adapter.push_transaction(transaction)
    end
  end

  config.before(:all) do
    DataMapper::Sweatshop.record_map = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = []}} # reset sweatshop cache as transactions destroy generated records
  end
end


class DateTime
  def self.metaclass
    class << self; self; end
  end

  def self.is(point_in_time)
    new_time = case point_in_time
      when String then DateTime.parse(point_in_time)
      when DateTime then point_in_time
      else raise ArgumentError.new("argument should be a string or time instance")
    end
    class << self
      alias old_now now
    end
    metaclass.class_eval do
      define_method :now do
        new_time
      end
    end
    yield
  ensure
    class << self
      alias now old_now
      undef old_now
    end
  end
end
