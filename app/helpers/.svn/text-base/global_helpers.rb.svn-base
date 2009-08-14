module Merb
  module GlobalHelpers

    def javascript_translations
      { 'UNKNOWN_ERROR' => _("Sorry, something went wrong. Please try again later."),
        'CONFIRM_ELEMENT_REMOVAL' => _("Are you sure you want to remove this element?"),
        'CONFIRM_FAVOURITE_REMOVAL' => _("Are you sure you want to remove this favourite?"),
        'CONFIRM_BOOKMARK_REMOVAL' => _("Are you sure you want to remove bookmark?"),
        'CONFIRM_LANGUAGE_SWITCH' => _("You have unsaved changes in the form. Do you really want to switch the language?"),
        'NEW_TOPIC' => _("New Topic"),
        'EDIT_TOPIC' => _("Edit Topic"),
        'FLAG_TOPIC' => _("Flag Topic"),
        'NEW_ELEMENT' => _("New Element"),
        'EDIT_ELEMENT' => _("Edit Element"),
        'FLAG_ELEMENT' => _("Flag Element"),
        'EDIT_FAVOURITE' => _("Edit Favourite"),
        'LOGIN' => _("Login"),
        'REGISTRATION' => _("Registration"),
        'ADD_BOOKMARK' => _("New Bookmark"),
        'EDIT_BOOKMARK' => _("Edit Bookmark"),
        'INVITE_FRIEND' => _("Invite Friend"),
        'JOIN_CLOSED_USER_GROUP' => _("Closed User Group"),
        'CONFIRM_FRIEND_REMOVAL' => _("Are you sure you want to break this friendship ?"),
        'CONFIRM_PENDING_FRIEND_REMOVAL' => _("Are you sure you want to cancel this friendship request?"),
        'CONFIRM_REQUESTED_FRIEND_REMOVAL' => _("Are you sure you want to cancel this request?"),
        'CONFIRM_EMIAL_INVITE_CANCEL' => _("Are you sure you want to cancel this invite?"),
        'FORGOTTEN_PASSWORD' => _("Forgotten Password"),
        'REQUEST_ACTIVATION' => _("Request Activation Mail"),
        'SELECT_ELEMENTS' => _("Please select at least one element."),
        'SELECT_ITEMS' => _("Please select at least one item."),
        'PROMOTE_TO_ADMIN' => _("Are you sure you want to promote this person to become administrator?"),
        'DEMOTE_FROM_ADMIN' => _("Are you sure you want to remove admin rights from this user?"),
        'PERMALINK' => _("Permalink"),
        'ABANDON_TOPIC' => _("Are you sure you want to abandon this topic?"),
        'BLOCK_TOPIC' => _('This topic will be hidden and not accessible by the users. Are you sure?'),
        'UNBLOCK_TOPIC' => _('Are you sure to unblock this topic?'),
        'BLOCK_ELEMENT' => _('This element will be hidden and not accessible by the users. Are you sure?'),
        'UNBLOCK_ELEMENT' => _('Are you sure to unblock this element?'),
        'REMOVE_TOPIC' => _('Are you really sure to permanently remove this topic from the system?'),
        'REMOVE_ELEMENT' => _('Are you really sure to permanently remove this element from the system?'),
        'REMOVE_USER' => _('Are you really sure to permanently remove this user from the system?'),
        'SELECT_NOTIFICATION' => _('You need to select at least one notification.'),
      }.to_json
    end

    def formatted_tags(tag_list)
      tag_list.join(", ")
    end

    def formatted_url(url)
      url.gsub(/https?\:\/\//, '')
    end

    def translate(content)
      return content unless content.is_a?(Hash)
      if (lang = params[:lang]) && (c = content[lang])
        c
      else
        translate_for_user(content, session.user, language_from_headers)
      end
    end

    def error_on(object, attribute)
      error = object.errors.on(attribute).try(:first)
      error ? %(<span class="error">#{error}</span>) : ""
    end
    
    # gravatars
    def gravatar(email, size)   
      hash = Digest::MD5.hexdigest(email.downcase)
      "http://www.gravatar.com/avatar/#{hash}?s=#{size}" 
    end

    def tag_cloud(tags, opts)
      return "" if tags.empty?
      min_count = tags.values.min
      max_count = tags.values.max
      range_size = (max_count - min_count) / 6.0

      html = %(<ul class="tag-cloud #{opts[:class]}">)
      tags.keys.sort.each do |tag_name|
        size = range_size > 0 ? ((tags[tag_name] - min_count) / range_size) : 3
        html << %(<li><a href="#" class="size-#{size.to_i}">#{tag_name}</a></li>)
      end
      html << '</ul>'
    end

    def selected_tags(selected, opts={})
      return "" if selected.empty?
      html = %(<span class="selected_tags #{opts[:class]}">Selected tags: )
      html << selected.map { |tag| link_to(tag, '#') }.join(" ")
      html << '</span>'
      html
    end

    def topic_tag_cloud(topics_tags, selected)
      html = "<h2>#{_("TOPIC CLOUD")}</h2>"
      html << selected_tags(selected, :class => "selected-topic-tags")
      tags = topics_tags.inject({}) { |a, tag| a[tag.name] = tag.non_private_topics_count.to_i; a }
      html << tag_cloud(tags, :class => "topic-tag-cloud")
    end

    def element_tag_cloud(elements_tags, selected)
      html = "<h2>#{_("ELEMENT CLOUD")}</h2>"
      html << selected_tags(selected, :class => "selected-element-tags")
      tags = elements_tags.inject({}) { |a, tag| a[tag.name] = tag.non_private_elements_count.to_i; a }
      html << tag_cloud(tags, :class => "element-tag-cloud")
    end

    def favourite_tag_cloud(favourites_tags, selected)
      html = "<h2>#{_("FAVOURITES CLOUD")}</h2>"
      html << selected_tags(selected, :class => "selected-favourites-tags")
      stats = UserTagStat.all(:user_id => session.user.id, :tag_id => favourites_tags.map { |t| t.id }).inject({}) { |a, stat| a[stat.tag_id] = stat.usage_in_favourites; a }
      mapping = favourites_tags.inject({}) { |a, tag| a[tag.name] = stats[tag.id]; a }
      html << tag_cloud(mapping, :class => "favourite-tag-cloud")
    end
    
    def bookmark_tag_cloud(bookmarks_tags, selected)
      html = "<h2>#{_("BOOKMARKS CLOUD")}</h2>"
      html << selected_tags(selected, :class => "selected-favourites-tags")
      stats = UserTagStat.all(:user_id => session.user.id, :tag_id => bookmarks_tags.map { |t| t.id }).inject({}) { |a, stat| a[stat.tag_id] = stat.usage_in_bookmarks; a }
      mapping = bookmarks_tags.inject({}) { |a, tag| a[tag.name] = stats[tag.id]; a }
      html << tag_cloud(mapping, :class => "bookmark-tag-cloud")
    end
    
    def bookmark_description(bookmark)
      html = "<h2>#{_("DESCRIPTION")}</h2>"
      html << "<p>#{bookmark.description}</p>"
    end
    
    def pagination_page(param=:page)
      params[param].to_i < 2 ? 1 : params[param].to_i
    end

    def paginator(page_count, opts={})
      opts = { :param => :page,
               :url => request.env["PATH_INFO"] + "?" + params.reject { |k,v| k =~ /^(id|page|action|controller|format|.+_page|_message)$/}.to_params
             }.merge!(opts)

      return "" unless page_count > 1
      paginate(pagination_page(opts[:param]), page_count, :prev_label => image_tag('icons/previous.png'),
                                  :next_label => image_tag('icons/next.png'), :outer_window => 2,
                                  :url => opts[:url], :page_param => opts[:param].to_s)
    end

    # sample usage thumbnail("http://onet.pl",:width => 60)
    def thumbnail(url, opts = {})
      if (Cayox::CONFIG[:thumb_api_key])
        opts.merge!({ :api_key => Cayox::CONFIG[:thumb_api_key] })
      end
      "http://api.thumbalizr.com/?url=#{url}&#{opts.to_params}"
    end

    def back_link_to_results
      link = nil
      url = request.env['HTTP_REFERER'].to_s
      if url =~ /\/(admin\/topics|mytopics|favourites|search|bookmarks)(\?.*)?$/ # we have matching referrer, we use it
        where = { "mytopics" => _("My Topics"), "favourites" => _("Favourites"), "search" => _("search results"), 
                  "bookmarks" => _("Bookmarks"), "admin/topics" => _("topics") }[$1]
        # store it in session so we can go back if user travels in elements and comes back to topic / favourite
        link = { :where => where, :url => url }
        (session[:back_links] ||= Mash.new)[request.env['REQUEST_URI']] = link
      elsif session[:back_links]
        curr_path = request.env['REQUEST_URI'].gsub("/blocked_elements", "")
        link = session[:back_links][curr_path]
      end

      link ? link_to(_("Back to #{link[:where]}"), link[:url]) : ""
    end

    def back_link_to_topic(parent)
      referrer = request.env['HTTP_REFERER'].to_s
      resource_url = resource(parent)
      if referrer =~ /\/(topics|favourites)\/\d+[^\/]*$/
        url = referrer
        (session[:topic_states] ||= {})[resource_url] = referrer
      else
        url = (session[:topic_states] || {})[resource_url] || resource_url
      end
      link_to(_("Back to '%s'") % translate(parent.name), url)
    end

    def language_options(object)
      all_languages = Language.all(:order => [:name])
      collection = []
      translations_languages = Language.all(:order => [:name], :iso_code => object.name.keys)
      user_languages = ([session.user.primary_language] + session.user.secondary_languages).compact
      collection << { :group_name => _("Existing translations"), :data => translations_languages } unless translations_languages.empty?
      collection << { :group_name => _("Your languages"), :data  => user_languages } unless user_languages.empty?
      collection << { :group_name => _("Other languages"), :data => all_languages - translations_languages - user_languages }
      collection
    end

    def get_language(object)
      lang = params[:lang]
      if object
        lang ||= (object.name.keys & [session.user.primary_language.try(:iso_code).to_s]).first
        lang ||= (object.name.keys & session.user.secondary_languages.map { |l| l.iso_code.to_s }).first
        lang ||= object.name.keys.first
      end
      lang ||= self.language_from_headers
      Language[lang] || Language[Cayox::CONFIG[:fallback_language_code]]
    end

    def invalid_tags_info(invalid_tags)
      unless invalid_tags.empty? || invalid_tags.first.blank?
        %(<p>#{_("Tag %s has been removed as it didn't provide any result.") % invalid_tags.map { |t| "<em><strong>#{t}</strong></em>" }.join(", ") }</p><br/>)
      end
    end

    def autocomplete_url_script(url)
      %(<script type="text/javascript">topAutocompleteUrl = "#{url}";</script>)
    end

  end
end
