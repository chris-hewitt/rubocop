# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for arrays defined using square brackets, i.e. [] - not %i[], %w(), etc.
    module BracketArray
      private

      # determine if an existing bracketed array can be converted to a percent array
      def check_bracketed_array(node, literal_prefix)
        return if bracketed_array_should_remain_bracketed?(node)

        determine_array_style_config(:brackets, node.values.size)

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

      def contains_child_with_spaces?(node)
        node.children.any? do |child_node|
          child_node.value && / /.match?(child_node.value)
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
