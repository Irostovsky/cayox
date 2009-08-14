require 'gettext'

CAYOX_LANGUAGES = ["de", "en", "fr", "pl"]
CAYOX_PO_PATH = Merb.root / "po"
CAYOX_I18N_MODULES = [Merb::Controller, DataMapper::Resource, Merb::Helpers::Form::Builder::ResourcefulFormWithErrors, Merb::MailController]

CAYOX_I18N_MODULES.each do |klass|
  klass.class_eval do
    include GetText
    bindtextdomain("cayox", :path => CAYOX_PO_PATH)
  end
end

class Merb::Controller
  attr_accessor :language_from_headers

  # set locale for current user / request
  before do
    primary_language_from_profile = ([session.user.primary_language.try(:iso_code)] & CAYOX_LANGUAGES)[0]
    secondary_language_from_profile = (session.user.secondary_languages.map { |lang| lang.iso_code } & CAYOX_LANGUAGES)[0]
    self.language_from_headers = extract_language_from_headers # instance variable on controller object
    locale_ = primary_language_from_profile || secondary_language_from_profile || self.language_from_headers || "en"
    # set locale for all modules that do translation
    CAYOX_I18N_MODULES.each do |klass|
      klass.class_eval do
        # Provide Local name with encoding included. 
        # Avoids gettext from evaluation this on the server...
        self.locale = locale_ + ".utf-8"
      end
    end
  end

protected
  def extract_language_from_headers
    languages = self.request.env['HTTP_ACCEPT_LANGUAGE']
    if languages
      languages = languages.split(',')
      languages.map! { |lang| lang.delete ' ' "\n" "\r" "\t" }
      languages.reject! { |lang| lang.empty? }
      languages.map! { |lang| lang.split ';q=' }
      languages.map! do |lang|
        if lang.size == 1
          [lang[0], 1.0]
        else
          [lang[0], lang[1].to_f]
        end
      end
      languages.map! { |lang| lang[0].split('-')[0] }
    else
      languages = []
    end
    (CAYOX_LANGUAGES && languages)[0]
  end
end

module Merb::Helpers::Form::Builder
  module Errorifier
    def error_messages_for(obj, error_class, build_li, header, before)
      obj ||= @obj
      return "" unless obj.respond_to?(:errors)

      sequel = !obj.errors.respond_to?(:each)
      errors = sequel ? obj.errors.full_messages : obj.errors

      return "" if errors.empty?

      header_message = header % [errors.size, errors.size == 1 ? "" : "s"]
      markup = %Q{<div class='#{error_class}'>#{header_message}<ul>}
      errors.each {|err| markup << (build_li % _((sequel ? err : err.first)))}
      markup << %Q{</ul></div>}
    end
  end
end

module Merb::Helpers::Form
  def error_messages_for(obj = nil, opts = {})
    current_form_context.error_messages_for(obj, opts[:error_class] || "error",
      opts[:build_li] || "<li>%s</li>",
      "<h2>%s</h2>" % (opts[:header] || _("Form submission failed because of %s problem(s)")),
      opts.key?(:before) ? opts[:before] : true)
  end
end

def translate_for_user(content, user, default_lang=nil)
  iso_code = user.preferred_content_language(content, default_lang)
  content[iso_code]
end

def language_hash_from_string(string, user, default_lang=nil)
  result = {}
  if user.primary_language.try(:iso_code)
    result[user.primary_language.try(:iso_code)] = string
 elsif ( user.secondary_languages.map { |l| l.iso_code }).first 
    result[ (user.secondary_languages.map { |l| l.iso_code }).first ] = string
  elsif default_lang
    result[default_lang] = string
  else
    result[Cayox::CONFIG[:fallback_language_code]] = string
  end
  result
end
