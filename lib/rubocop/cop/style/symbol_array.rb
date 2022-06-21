# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for array literals made up of symbols that are not
      # using the %i() syntax.
      #
      # Alternatively, it checks for symbol arrays using the %i() syntax on
      # projects which do not want to use that syntax.
      #
      # Configuration option: MinSize
      # If set, arrays with fewer elements than this value will not trigger the
      # cop. For example, a `MinSize` of `3` will not enforce a style on an
      # array of 2 or fewer elements.
      #
      # @example EnforcedStyle: percent (default)
      #   # good
      #   %i[foo bar baz]
      #
      #   # bad
      #   [:foo, :bar, :baz]
      #
      # @example EnforcedStyle: brackets
      #   # good
      #   [:foo, :bar, :baz]
      #
      #   # bad
      #   %i[foo bar baz]
      class SymbolArray < Base
        include ArrayMinSize
        include ArraySyntax
        include BracketedArray
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector

        PERCENT_MSG = 'Use `%i` or `%I` for an array of symbols.'
        BRACKET_MSG = 'Use `%<prefer>s` for an array of symbols.'
        BRACKET_DELIMITERS = ['[', ']'], [':', ''], [":'", "'"]

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if bracketed_array_of?(:sym, node)
            check_bracketed_array(node, 'i')
          elsif node.percent_literal?(:symbol)
            check_percent_array(node)
          end
        end

        private

        def bracketed_array_should_remain_bracketed?(node)
          contains_child_with_spaces?(node) ||
            comments_in_array?(node) ||
            below_array_length?(node) ||
            in_invalid_context_for_percent_array?(node)
        end

        def percent_array_should_become_bracketed?(_node)
          false
        end

        def element_for_bracketed_array(node)
          if node.dsym_type?
            string_literal = to_string_literal(node.source)

            ":#{trim_string_interpolation_escape_character(string_literal)}"
          else
            to_symbol_literal(node.value.to_s)
          end
        end

        def to_symbol_literal(string)
          if can_be_converted_to_symbol_without_quoting?(string)
            ":#{string}"
          else
            ":#{to_string_literal(string)}"
          end
        end
      end
    end
  end
end
