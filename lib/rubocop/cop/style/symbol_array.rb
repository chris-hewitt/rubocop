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
        include BracketedArray
        include ConfigurableEnforcedStyle
        include PercentArray
        extend AutoCorrector

        PERCENT_MSG = 'Use `%i` or `%I` for an array of symbols.'
        BRACKET_MSG = 'Use `%<prefer>s` for an array of symbols.'

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if node.square_brackets? && contains_only?(node, :sym)       # [rubocop-ast], bracketed_array
            check_bracketed_array(node, 'i')                           # bracketed_array
          elsif node.percent_literal?(:symbol)                         # [rubocop-ast]
            check_percent_array(node)                                  # percent_array
          end
        end

        private

        def bracketed_array_should_remain_bracketed?(node)
          any_children_contain_spaces?(node) ||                        # bracketed_array
            comments_in_array?(node) ||                                # bracketed_array
            below_array_length?(node) ||                               # array_min_size
            invalid_percent_array_context?(node)                       # bracketed_array
        end

        def percent_array_must_become_bracketed?(node)
          brackets_required?(node)
        end

        def brackets_required?(_node)         # used by percent_array#check_percent_array()
          false
        end

        def element_for_bracketed_array(node)         # used by percent_array#build_bracketed_array()
          if node.dsym_type?
            string_literal = to_string_literal(node.source)                    # util

            ":#{trim_string_interpolation_escape_character(string_literal)}"   # util
          else
            # pp [node.value.to_s, node.source, node.noderen]
            to_symbol_literal(node.value.to_s)                                 # util
          end
        end

        def to_symbol_literal(string)
          if symbol_without_quote?(string)
            ":#{string}"
          else
            ":#{to_string_literal(string)}"
          end
        end
      end
    end
  end
end
