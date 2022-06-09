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

                  def end_content(source)
                    result = /\A(\s*)(\]|\)|\})/.match(source.split("\n").last)
                    "\n#{result[1]}" if result
                  end

      def generated_bracket_array(node, force_single_line = false)
        if node.multiline? && !force_single_line
          multiline_bracket_array(node)
        else
          single_line_bracket_array(node)
        end
      end

                  # def line_breaks(node, array_source, previous_line_num, base_line_num, node_index)
                  def line_breaks(node, array_source, previous_node, base_line_num, node_index)
                    # previous_node: the previous sibling if it exists, or else the opening bracket of the parent array
                    # previous_line_num: for first element, equals first line of array
                    #                    otherwise last line of previous element
                    #                    i.e the last line of the previous node of any level
                    if node.first_line == previous_line_num # we are on the same line as the last line of the previous node (sibling or parent)
                      node_index.zero? && node.first_line == base_line_num ? '' : ' '
                    else
                      source_in_lines = array_source.split("\n")
                      process_lines(node, previous_line_num, base_line_num, source_in_lines)
                    end
                  end

                  def multiline_contents_orig(node)
                    contents = process_multiline_elements(node)
                    contents << end_content(node.source)
                    contents.join
                  end

      def offense_message(node)
        recommended_array = generated_bracket_array(node, true)
        message = format(self.class::BRACKET_MSG, prefer: recommended_array)
      end

                  def process_lines(node, previous_line_num, base_line_num, array_source_in_lines)
                    begin_line_num = previous_line_num - base_line_num + 1
                    end_line_num = node.first_line - base_line_num + 1
                    lines = array_source_in_lines[begin_line_num...end_line_num]
                    "\n#{lines.join("\n").split(node.source).first || ''}"
                  end

                  def process_multiline_elements_orig(node)
                    base_line_num = node.first_line # first line of array
                    final_line_num = node.last_line # last line of array
                    prev_line_num = base_line_num # first line of array
                    prev_node = node
                    node.children.map.with_index do |element_node, index|
                      # line_breaks = line_breaks(element_node, node.source, prev_line_num, base_line_num, index)
                      line_breaks = line_breaks(element_node, node.source, prev_node, base_line_num, index)
                      prev_line_num = element_node.last_line # last line of element
                      delimiter = (index == 0 ? '' : ',')
                      delimiter + line_breaks + element_for_bracketed_array(element_node)
                      prev_node = element_node
                    end
                  end

      def multiline_bracket_array(array_node)
        array_source_in_lines = array_node.source.split("\n")
        last_line_of_prev_node = array_node.first_line
        generated_source = ''
        array_node.children.each.with_index do |element_node, element_index|
          preceding_delimiter = (element_index == 0 ? '' : ',')
          preceding_whitespace = if element_node.first_line == last_line_of_prev_node
                                   (element_index.zero? && element_node.first_line == array_node.first_line) ? '' : ' '
                                 else
                                   begin_line_num = last_line_of_prev_node - array_node.first_line + 1
                                   end_line_num = element_node.first_line - array_node.first_line + 1
                                   lines = array_source_in_lines[begin_line_num...end_line_num]
                                   something = lines.join("\n").split(element_node.source).first || ''
                                   "\n#{something}"
                                 end
          last_line_of_prev_node = element_node.last_line
          generated_source += preceding_delimiter + preceding_whitespace + element_for_bracketed_array(element_node)
        end
        whitespace_before_closing_bracket = begin
          result = /\A(\s*)(\]|\)|\})/.match(array_source_in_lines.last)
          result ? "\n#{result[1]}" : ''
        end
        generated_source += whitespace_before_closing_bracket
        "[#{generated_source}]"
      end

      def single_line_bracket_array(node)
        elements = node.children.map do |word_node|
          element_for_bracketed_array(word_node)
        end
        "[#{elements.join(', ')}]"
      end
    end
  end
end
