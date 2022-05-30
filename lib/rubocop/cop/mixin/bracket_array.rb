# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for arrays defined using square brackets, i.e. [] - not %i[], %w(), etc.
    module BracketArray
      private

      # determine if an existing bracketed array can be converted to a percent array
      def check_bracketed_array(node, literal_prefix)      # used by symbol_array#on_array() / word_array#on_array()
        return if bracketed_array_should_remain_bracketed?(node)       # symbol_array / word_array

        determine_array_style_config(:brackets, node.values.size)              # array_min_size

        return unless style == :percent

        add_offense(node, message: self.class::PERCENT_MSG) do |corrector|
          percent_literal_corrector = PercentLiteralCorrector.new(@config, @preferred_delimiters)
          percent_literal_corrector.correct(corrector, node, literal_prefix)
        end
      end

      def comments_in_array?(node)
        line_span = node.source_range.first_line...node.source_range.last_line
        processed_source.each_comment_in_lines(line_span).any?
      end

      # def array_of_strings_only?(node, child_type)
      #   array_contains_only?(node, :str)
      # end

      # def array_of_symbols_only?(node)
      #   array_contains_only?(node, :sym)
      # end

      # def array_contains_only?(node, child_type)
      #   node.children.map(&:type).uniq == [child_type]
      # end

      def contains_child_with_spaces?(node)
        node.children.any? do |child_node|
          child_node.str_content && / /.match?(child_node.str_content)
        end
      end

      # Ruby does not allow percent arrays in an ambiguous block context.
      #
      # @example
      #
      #   foo %i[bar baz] { qux }
      def in_invalid_context_for_percent_array?(node)
        parent = node.parent

        parent&.send_type? && parent.arguments.include?(node) &&
          !parent.parenthesized? && parent&.block_literal?
      end
    end
  end
end
