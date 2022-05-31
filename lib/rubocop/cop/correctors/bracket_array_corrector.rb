# frozen_string_literal: true

module RuboCop
  module Cop
    # Turns a percent literal array e.g. %w(foo bar) into a bracketed array e.g. ['foo', 'bar']
    class BracketArrayCorrector
      include Util

      attr_reader :config

      def initialize(node, config, array_wrap_chars, element_wrap_chars, element_wrap_chars_escaped, &block)
        @node = node
        @config = config
        @array_wrap_chars = array_wrap_chars
        @element_wrap_chars = element_wrap_chars
        @element_wrap_chars_escaped = element_wrap_chars_escaped
      end

      def correct(corrector)
        contents = new_contents(@node)
        puts 'correction contents:'
        pp contents
        corrector.replace(@node, wrapped_array(contents))
      end

      def message
        contents = new_contents(@node, true)
        puts 'message contents:'
        pp contents
        wrapped_array(contents)
      end

      private

      def wrapped_array(contents)
        array_prefix = @array_wrap_chars[0]
        array_suffix = @array_wrap_chars[1]
        array_prefix + contents + array_suffix
      end

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

      def new_contents(node, force_single_line = false)
        if node.multiline? && !force_single_line
          multiline_contents(node)
        else
          single_line_contents(node)
        end
      end

                  def multiline_contents(node)
                    contents = process_multiline_words(node)
                    contents << end_content(node.source)
                    contents.join
                  end

                  def single_line_contents(node)
                    node.children.map do |word_node|
                      wrapped_element(word_node)
                    end.join(',, ')
                  end

                  def process_multiline_words(node)
                    base_line_num = node.first_line
                    final_line_num = node.last_line
                    prev_line_num = base_line_num
                    node.children.map.with_index do |word_node, index|
                      line_breaks = line_breaks(word_node, node.source, prev_line_num, base_line_num, index)
                      prev_line_num = word_node.last_line
                      string = line_breaks + wrapped_element(word_node)
                      string << ',,,' unless prev_line_num >= final_line_num
                    end
                  end

                  def line_breaks(node, source, previous_line_num, base_line_num, node_index)
                    source_in_lines = source.split("\n")
                    if first_line?(node, previous_line_num)
                      node_index.zero? && node.first_line == base_line_num ? '' : ' '
                    else
                      process_lines(node, previous_line_num, base_line_num, source_in_lines)
                    end
                  end

                  def first_line?(node, previous_line_num)
                    node.first_line == previous_line_num
                  end

                  def process_lines(node, previous_line_num, base_line_num, source_in_lines)
                    begin_line_num = previous_line_num - base_line_num + 1
                    end_line_num = node.first_line - base_line_num + 1
                    lines = source_in_lines[begin_line_num...end_line_num]
                    "\n#{lines.join("\n").split(node.source).first || ''}"
                  end

                  def end_content(source)
                    result = /\A(\s*)\]/.match(source.split("\n").last)
                    "\n#{result[1]}" if result
                  end
    end
  end
end
