# frozen_string_literal: true

module RuboCop
  module Cop
    class BracketedArrayCorrector
      include Util

      attr_reader :config

      def initialize(config, array_wrap_chars, element_wrap_chars, element_wrap_chars_escaped)
        @config = config
        @array_wrap_chars = array_wrap_chars
        @element_wrap_chars = element_wrap_chars
        @element_wrap_chars_escaped = element_wrap_chars_escaped
      end

      def correct(corrector, node)
        escape = escape_words?(node)
        contents = new_contents(node, escape)
        wrap_array(corrector, node, contents)
      end

      private

      def wrap_array(corrector, node, contents)
        array_prefix = @array_wrap_chars[0]
        array_suffix = @array_wrap_chars[1]
        corrector.replace(node, array_prefix + contents + array_suffix)
      end

      def wrapped_element(node)
        # element_prefix = needs_escaping?(node) ? @element_wrap_chars[0] : @element_wrap_chars_escaped[0]
        # element_suffix = needs_escaping?(node) ? @element_wrap_chars[1] : @element_wrap_chars_escaped[1]

        if symbol_without_quote?(node.source)
          # "::#{node.source}"
          @element_wrap_chars[0] + node.source + @element_wrap_chars[1]
        else
          # "::#{to_string_literal(node.source)}"
          # element_prefix + to_string_literal(node.source) + element_suffix
          @element_wrap_chars_escaped[0] + node.source + @element_wrap_chars_escaped[1]
        end

      end

      def escape_words?(node)
        node.children.any? { |w| needs_escaping?(w.children[0]) }
      end

      def delimiters_for(type)
        PreferredDelimiters.new(type, config, preferred_delimiters).delimiters
      end

      def needs_quoted?(node)
      end

      def new_contents(node, escape)
        if node.multiline?
          autocorrect_multiline_words(node, escape)
        else
          autocorrect_words(node, escape)
        end
      end

      def autocorrect_multiline_words(node, escape)
        contents = process_multiline_words(node, escape)
        contents << end_content(node.source)
        contents.join
      end

      def autocorrect_words(node, escape)
        node.children.map do |word_node|
          wrapped_element(word_node)
        end.join(', ')
      end

      def process_multiline_words(node, escape)
        base_line_num = node.first_line
        final_line_num = node.last_line
        prev_line_num = base_line_num
        node.children.map.with_index do |word_node, index|
          line_breaks = line_breaks(word_node, node.source, prev_line_num, base_line_num, index)
          prev_line_num = word_node.last_line
          string = line_breaks + wrapped_element(word_node)
          string << ',' unless prev_line_num >= final_line_num
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

      def fix_escaped_content(word_node, escape)
        content = +word_node.children.first.to_s
        content = escape_string(content) if escape
        content
      end

      def end_content(source)
        result = /\A(\s*)\]/.match(source.split("\n").last)
        "\n#{result[1]}" if result
      end
    end
  end
end
