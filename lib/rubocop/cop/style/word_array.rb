# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for array literals made up of word-like
      # strings, that are not using the %w() syntax.
      #
      # Alternatively, it can check for uses of the %w() syntax, in projects
      # which do not want to include that syntax.
      #
      # NOTE: When using the `percent` style, %w() arrays containing a space
      # will be registered as offenses.
      #
      # Configuration option: MinSize
      # If set, arrays with fewer elements than this value will not trigger the
      # cop. For example, a `MinSize` of `3` will not enforce a style on an
      # array of 2 or fewer elements.
      #
      # @example EnforcedStyle: percent (default)
      #   # good
      #   %w[foo bar baz]
      #
      #   # bad
      #   ['foo', 'bar', 'baz']
      #
      #   # bad (contains spaces)
      #   %w[foo\ bar baz\ quux]
      #
      # @example EnforcedStyle: brackets
      #   # good
      #   ['foo', 'bar', 'baz']
      #
      #   # bad
      #   %w[foo bar baz]
      #
      #   # good (contains spaces)
      #   ['foo bar', 'baz quux']
      class WordArray < Base
        include ArrayMinSize
        include ArraySyntax
        include BracketedArray
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector

        PERCENT_MSG = 'Use `%w` or `%W` for an array of words.'
        BRACKET_MSG = 'Use `%<prefer>s` for an array of words.'
        BRACKET_DELIMITERS = ['[', ']'], ["'", "'"], ['"', '"']

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if bracketed_array_of?(:str, node)
            check_bracketed_array(node, 'w')
          elsif node.percent_literal?(:string)
            check_percent_array(node)
          end
        end

        private

        def as_utf8(string)
          string.dup.force_encoding(::Encoding::UTF_8)
        end

        def bracketed_array_should_remain_bracketed?(node)
          contains_non_utf8_child?(node) ||
            contains_child_not_matching_regex?(node) ||
            contains_child_with_spaces?(node) ||
            comments_in_array?(node) ||
            below_array_length?(node) ||
            in_invalid_context_for_percent_array?(node)
        end

        def contains_child_not_matching_regex?(node)
          regex = word_regex
          node.children.any? do |child_node|
            regex && child_node.str_content && !regex.match?(as_utf8(child_node.str_content))
          end
        end

        def contains_non_utf8_child?(node)
          node.children.any? do |child_node|
            child_node.str_content && !valid_utf8?(child_node.str_content)
          end
        end

        def percent_array_should_become_bracketed?(node)
          contains_non_utf8_child?(node) ||
            contains_child_with_spaces?(node)
        end

        def valid_utf8?(string)
          as_utf8(string).valid_encoding?
        end

        def word_regex
          Regexp.new(cop_config['WordRegex'])
        end

        def element_for_bracketed_array(node)
          if node.dstr_type?
            string_literal = to_string_literal(node.source)

            trim_string_interpolation_escape_character(string_literal)
          else
            to_string_literal(node.value.to_s)
          end
        end
      end
    end
  end
end
