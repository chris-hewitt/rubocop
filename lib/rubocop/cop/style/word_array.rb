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
        include BracketArray
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector

        PERCENT_MSG = 'Use `%w` or `%W` for an array of words.'
        BRACKET_MSG = 'Use `%<prefer>s` for an array of words.'

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if node.square_brackets? && node.contains_only?(:str)        # [rubocop-ast], bracket_array
            check_bracketed_array(node, 'w')                           # bracket_array
          elsif node.percent_literal?(:string)                         # [rubocop-ast]
            check_percent_array(node)                                  # percent_array
          end
        end

        private

        def as_utf8(string)
          string.dup.force_encoding(::Encoding::UTF_8)
        end

        def bracketed_array_should_remain_bracketed?(node)
          contains_non_utf8_child?(node) ||
            contains_child_not_matching_regex?(node) ||
            contains_child_with_spaces?(node) ||                       # bracket_array
            comments_in_array?(node) ||                                # bracket_array
            below_array_length?(node) ||                               # array_min_size
            in_invalid_context_for_percent_array?(node)                # bracket_array
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

        def percent_array_should_become_bracketed?(node)               # used by percent_array#check_percent_array()
          contains_non_utf8_child?(node) ||
            contains_child_with_spaces?(node)                          # bracket_array
        end

        def valid_utf8?(string)
          as_utf8(string).valid_encoding?
        end

        def word_regex
          Regexp.new(cop_config['WordRegex'])
        end

        def element_for_bracketed_array(node)              # used by percent_array#build_bracketed_array()
          if node.dstr_type?
            string_literal = to_string_literal(node.source)                    # util

            trim_string_interpolation_escape_character(string_literal)         # util
          else
            # pp [node.value.to_s, node.source, node.noderen]
            to_string_literal(node.value.to_s)                                 # util
          end
        end
      end
    end
  end
end
