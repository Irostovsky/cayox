class Object
  ##
  #   @person ? @person.name : nil
  # vs
  #   @person.try(:name)
  def try(method)
    send method if respond_to? method
  end
end

if RUBY_VERSION < "1.8.7"
  class Array
    def group_by
      inject({}) do |groups, element|
        (groups[yield(element)] ||= []) << element
        groups
      end
    end
  end
end

# reimplementing options_for with support for ordered option groups (given as array of hashes)
module Merb::Helpers::Form::Builder
  class Base
    def options_for(attrs)
      blank, prompt = attrs.delete(:include_blank), attrs.delete(:prompt)
      b = blank || prompt ? tag(:option, prompt || "", :value => "") : ""

      # yank out the options attrs
      collection, selected, text_method, value_method =
        attrs.extract!(:collection, :selected, :text_method, :value_method)

      # if the collection is an Array of Hashes
      if collection.first.is_a?(Hash)
        (collection.map do |group|
          tag(:optgroup, options(group[:data], text_method, value_method, selected), :label => group[:group_name])
        end).join
      else
        options(collection || [], text_method, value_method, selected, b)
      end
    end
  end
end

class String
  def slug
    self.downcase.strip.gsub(/\s+/, '-').gsub(/[^a-z0-9-]/, '').gsub(/-{2,}/, '-')
  end
end


# fix for extlib 0.9.11 bug
module Extlib
  module Hook
    module ClassMethods
      def define_hook_stack_execution_methods(target_method, scope)
        unless registered_as_hook?(target_method, scope)
          raise ArgumentError, "#{target_method} has not be registered as a hookable #{scope} method"
        end

        hooks = hooks_with_scope(scope)

        before_hooks = hooks[target_method][:before]
        before_hooks = before_hooks.map{ |info| inline_call(info, scope) }.join("\n")

        after_hooks = hooks[target_method][:after]
        after_hooks = after_hooks.map{ |info| inline_call(info, scope) }.join("\n")

        before_hook_name = hook_method_name(target_method, 'execute_before', 'hook_stack')
        after_hook_name = hook_method_name(target_method, 'execute_after', 'hook_stack')

        hooks[target_method][:in].class_eval <<-RUBY, __FILE__, __LINE__ + 1
          #{scope == :class ? 'class << self' : ''}

          private

          remove_method :#{before_hook_name} if instance_methods(false).any? { |m| m.to_sym == :#{before_hook_name} }
          def #{before_hook_name}(*args)
          #{before_hooks}
          end

          remove_method :#{after_hook_name} if instance_methods(false).any? { |m| m.to_sym == :#{after_hook_name} }
          def #{after_hook_name}(*args)
          #{after_hooks}
          end

          #{scope == :class ? 'end' : ''}
          RUBY
      end
    end
  end
end