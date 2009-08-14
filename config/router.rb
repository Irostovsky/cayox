# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   match("/books/:book_id/:action").
#     to(:controller => "books")
#
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can specify conditions on the placeholder by passing a hash as the second
# argument of "match"
#
#   match("/registration/:course_name", :course_name => /^[a-z]{3,5}-\d{5}$/).
#     to(:controller => "registration")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do

  # RESTful routes
  namespace :plugin do
    resource :config do
      member :default, :method => :get
    end
    resources :bookmarks
  end

  resources :users do
    collection :request_password, :method => [:get, :post]
    collection :reset_password, :method => :get
    collection :activate, :method => :get
    collection :complete_registration, :method => :get
    collection :complete_resending_activation, :method => :get
    collection :password_reset_details, :method => :get
    collection :resend_activation, :method => [:get, :post]
    member :profile, :to => 'edit'
  end

  resources :topics do
    member :join, :to => 'join_closed_group'
    member :permalink
    member :element_tags_autocomplete
    member :abandon
    member :adopt
    collection :add, :to => 'add_elements_from_bookmarks'

    resources :elements do
      member :permalink
      resources :flags
    end

    resources :sig_members do
      member :accept
      member :reject
    end

    resources :membership_requests do
      member :accept
      member :reject
    end

    resources :flags
  end

  resources :mytopics do
    collection :tags_autocomplete
  end

  resources :friends do
    member :accept, :to => 'accept'
    member :cancel, :to => 'cancel'
    member :reject, :to => 'reject'
    member :break,  :to => 'break'
    member :cancel_invite, :to => 'cancel_invite'
  end

  resources :bookmarks do
    collection :tags_autocomplete
  end

  resources :comments do
    collection :element_comments, :method => [:get]
    collection :topic_comments, :method => [:get]
  end

  resources :favourites do
    resources :elements do
      member :accept
      member :reject
      member :propose
    end
    collection :tags_autocomplete
    member :element_tags_autocomplete
    member :fresh
    member :confirm_fresh
  end

  resources :element_propositions do
    member :accept
    member :reject
    collection :confirm
  end

  resources :flags do
    collection :confirm
  end

  match("/admin/topics/blocked").to(:controller => 'admin/topics', :action => 'index', :blocked => true)
  match("/admin/topics/:id/blocked_elements").to(:controller => 'admin/topics', :action => 'show', :blocked => true)

  namespace :admin do

    resources :users do
      member :block
      member :unblock
      member :promote, :to => "promote_to_admin"
      member :demote, :to => "demote_from_admin"
      member :resend_activation_mail, :to => "send_welcome_mail"
      member :remove
      member :password_reset_link
      collection :test
    end

    resources :topics do
      collection :blocked
      collection :tags_autocomplete
      member :element_tags_autocomplete
      member :blocked_elements
      member :block
      member :unblock
      member :remove
      resources :elements do
        member :block
        member :unblock
        member :remove
      end
      resources :sig_members
    end

    resources :flags do
      collection :confirm
    end

    resources :notifications do
      collection :resend
    end

  end


  slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")

  # search
  match("/search").to(:controller => 'search', :action => 'index').name(:search)
#  match("/mytopics").to(:controller => 'search', :action => 'index', :users_topics_only => true).name(:mytopics)

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you're heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  default_routes

  # home
  match('/').to(:controller => 'search', :action =>'home').name(:home)
end
