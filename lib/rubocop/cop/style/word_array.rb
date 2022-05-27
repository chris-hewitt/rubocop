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
        include BracketedArray
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector

        PERCENT_MSG = 'Use `%w` or `%W` for an array of words.'
        BRACKET_MSG = 'Use `%<prefer>s` for an array of words.'

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if node.square_brackets? && node.contains_only?(:str)        # [rubocop-ast], bracketed_array
            check_bracketed_array(node, 'w')                           # bracketed_array
          elsif node.percent_literal?(:string)                         # [rubocop-ast]
            check_percent_array(node)                                  # percent_array
          end
        end

        private

        def bracketed_array_should_remain_bracketed?(node)
          complex_content?(node) ||
            comments_in_array?(node) ||                                # bracketed_array
            below_array_length?(node) ||                               # array_min_size
            in_invalid_context_for_percent_array?(node)                # bracketed_array
        end

        def percent_array_must_become_bracketed?(node)
          brackets_required?(node)
        end

        def complex_content?(node, complex_regex: word_regex)
          node.children.any? do |s|
            next unless s.str_content

            string = s.str_content.dup.force_encoding(::Encoding::UTF_8)
            !string.valid_encoding? ||
              (complex_regex && !complex_regex.match?(string)) ||
              / /.match?(string)
          end
        end

        def brackets_required?(node)         # used by percent_array#check_percent_array()
          # Disallow %w() arrays that contain invalid encoding or spaces
          node.children.any? do |s|
            next unless s.str_content

            string = s.str_content.dup.force_encoding(::Encoding::UTF_8)
            !string.valid_encoding? || / /.match?(string)
          end
        end

        def word_regex
          Regexp.new(cop_config['WordRegex'])
        end

        def element_for_bracketed_array(node)         # used by percent_array#build_bracketed_array()
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
