# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for arrays defined using a percent literal syntax: %i(foo bar), %W[foo bar], etc.
    module PercentArray
      private

      # determine if an existing percent array can be converted to a bracketed array
      def check_percent_array(node)                                            # used by symbol_array#on_array() / word_array#on_array()
        determine_array_style_config(:percent, node.values.size)               # array_min_size
        brackets_required = percent_array_should_become_bracketed?(node)       # symbol_array / word_array

        return unless style == :brackets || brackets_required

        self.config_to_allow_offenses = { 'Enabled' => false } if brackets_required                              # configurable_enforced_style

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

        add_offense(node, message: offense_message(node)) do |corrector|
          convert_to_bracket_array(corrector, node)
        end
      end

      def convert_to_bracket_array(corrector, node)
        array = generated_bracket_array(node)
        corrector.replace(node, array)
      end

      def generated_bracket_array(node, force_single_line = false)
        if node.multiline? && !force_single_line
          multiline_bracket_array(node)
        else
          single_line_bracket_array(node)
        end
      end

      def offense_message(node)
        recommended_array = generated_bracket_array(node, true)
        format(self.class::BRACKET_MSG, prefer: recommended_array)
      end

      def multiline_bracket_array(array_node)
        last_line_of_prev_node = array_node.first_line
        puts 'source:'
        pp array_node.source.lines
        elements_with_preceding_whitespace = array_node.children.map.with_index do |element_node, element_index|
          element_on_same_line_as_prev = (element_node.first_line == last_line_of_prev_node)
          preceding_whitespace = if element_on_same_line_as_prev
                                   element_index.zero? ? '' : ' '
                                 else
                                   lines_from_end_of_prev_to_start_of_current = begin
                                     begin_line_num = last_line_of_prev_node - array_node.first_line + 1
                                     end_line_num = element_node.first_line - array_node.first_line + 1
                                     array_node.source.lines[begin_line_num...end_line_num]
                                   end
                                   pp lines_from_end_of_prev_to_start_of_current
                                   pp element_node.source
                                   something = lines_from_end_of_prev_to_start_of_current.join("\n").split(element_node.source).first
                                   "\n#{something}"
                                 end
          last_line_of_prev_node = element_node.last_line
          preceding_whitespace + element_for_bracketed_array(element_node)
        end
        whitespace_before_closing_bracket = begin
          result = /\A(\s*)(\]|\)|\})/.match(array_node.source.lines.last)
          result ? "\n#{result[1]}" : ''
        end
        ['[', elements_with_preceding_whitespace.join(','), whitespace_before_closing_bracket, ']'].join
      end

      def single_line_bracket_array(node)
        elements = node.children.map do |element_node|
          element_for_bracketed_array(element_node)
        end
        "[#{elements.join(', ')}]"
      end
    end
  end
end
