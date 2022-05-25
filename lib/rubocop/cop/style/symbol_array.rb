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

        class << self
          attr_accessor :largest_brackets
        end

        def on_array(node)
          if bracketed_array_of?(:sym, node)
            return if symbols_contain_spaces?(node)

            check_bracketed_array(node, 'i')              # bracketed_array
          elsif node.percent_literal?(:symbol)
            check_percent_array(node)                     # percent_array
          end
        end

        private

        def symbols_contain_spaces?(node)
          # pp [node, node.source, node.values, *node]
          node.children.any? do |sym|
            # pp [sym, sym.source, nil, *sym]
            content, = *sym
            / /.match?(content)
          end
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
