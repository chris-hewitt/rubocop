# frozen_string_literal: true

module RuboCop
  module Cop
    # Turns a percent literal array e.g. %w(foo bar) into a bracketed array e.g. ['foo', 'bar']
    class BracketedArrayCorrector
      include Util

      attr_reader :config

      def initialize(node, config, array_wrap_chars, element_wrap_chars, element_wrap_chars_escaped, &block)
        @node = node
        @config = config
        @array_wrap_chars = array_wrap_chars
        @element_wrap_chars = element_wrap_chars
        @element_wrap_chars_escaped = element_wrap_chars_escaped
      end



      private

      def wrapped_element(node)
        needs_escaping = !can_be_converted_to_symbol_without_quoting?(node.source)

        # element_prefix = needs_escaping?(node) ? @element_wrap_chars[0] : @element_wrap_chars_escaped[0]
        # element_suffix = needs_escaping?(node) ? @element_wrap_chars[1] : @element_wrap_chars_escaped[1]

        if needs_escaping
          element_prefix = @element_wrap_chars_escaped[0]
          element_suffix = @element_wrap_chars_escaped[1]
          element_prefix + to_string_literal(node.source) + element_suffix
        else
          element_prefix = @element_wrap_chars[0]
          element_suffix = @element_wrap_chars[1]
          element_prefix + node.source + element_suffix
        end
      end

                  def delimiters_for(type)
                    PreferredDelimiters.new(type, config, preferred_delimiters).delimiters
                  end
    end
  end
end
