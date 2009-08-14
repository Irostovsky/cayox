# use PathPrefix Middleware if :path_prefix is set in Merb::Config
if prefix = ::Merb::Config[:path_prefix]
  use Merb::Rack::PathPrefix, prefix
end

# comment this out if you are running merb behind a load balancer
# that serves static files
use Merb::Rack::Static, Merb.dir_for(:public)

use Rack::RevisionInfo, :path => Merb.root, :inner_html => ".footer li.revision" if Cayox::CONFIG[:show_revision]

# this is our main merb application
run Merb::Rack::Application.new
