# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for arrays defined using a percent literal syntax, e.g. %w(foo bar)
    module PercentArray
      private

      # determine if an existing percent array can be converted to a bracketed array
      def check_percent_array(node)                                            # used by symbol_array#on_array() / word_array#on_array()
        determine_array_style_config(:percent, node.values.size)               # array_min_size
        brackets_required = percent_array_should_become_bracketed?(node)       # symbol_array / word_array

        return unless style == :brackets || brackets_required

        no_acceptable_style! if brackets_required                              # configurable_enforced_style

        #                                               brackets_required               !brackets_required
        # array_style_detected && style == :brackets    continue; no_acceptable_style!  continue
        # array_style_detected && style != :brackets    continue; no_acceptable_style!  return

        # if style == :brackets
        #   # continue
        # elsif brackets_required
        #   config_to_allow_offenses = { 'Enabled' => false }
        #   # continue
        # else
        #   return
        # end

        bracketed_array = build_bracketed_array(node)
        message = format(self.class::BRACKET_MSG, prefer: bracketed_array)     # symbol_array / word_array

        add_offense(node, message: message) do |corrector|
          corrector.replace(node, bracketed_array)

          # percent_literal_corrector = BracketedArrayCorrector.new(@config, ['[', ']'], ['::', ''], ["::'", "'"])
          # percent_literal_corrector.correct(corrector, node)

          # percent_literal_corrector.correct(corrector, node) do |element_content|
          #   element_prefix = needs_escaping?(node) ? '"' : "'"
          #   element_suffix = needs_escaping?(node) ? '"' : "'"
          #   element_prefix + element_content + element_suffix
          # end

          # percent_literal_corrector.correct(corrector, node) do |element_content|
          #   '::' + element_content
          # end
        end
      end

      def build_bracketed_array(node)
        elements = node.children.map do |child_node|
          element_for_bracketed_array(child_node)          # symbol_array / word_array
        end

        "[#{elements.join(', ')}]"
      end
    end
  end
end
