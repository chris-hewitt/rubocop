# frozen_string_literal: true

module RuboCop
  module Cop
    # Handles the `MinSize` configuration option for array-based cops
    # `Style/SymbolArray` and `Style/WordArray`, which check for use of the
    # relevant percent literal syntax such as `%i[...]` and `%w[...]`
    module ArrayMinSize
      private

      def below_array_length?(node)
        node.values.length < min_size_config
      end

      def min_size_config
        cop_config['MinSize']
      end

      def update_size_trackers_and_config_to_allow_offenses(array_type, element_type, node)
        if array_type == :bracket
          return if element_type == :symbol && node.contains_element_with_space?
          return if element_type == :word && complex_content?(node)
          return if allowed_bracket_array?(node)
          array_style_detected(:brackets, node.values.size)
        elsif array_type == :percent
          array_style_detected(:percent, node.values.size)
          # If in percent style but brackets are required due to
          # string content, the file should be excluded in auto-gen-config
          no_acceptable_style! if percent_array_should_become_bracketed?(node)
        end
      end


      def array_style_detected(style, ary_size) # rubocop:todo Metrics/AbcSize
        cfg = config_to_allow_offenses
        return if cfg['Enabled'] == false

        largest_brackets = largest_brackets_size(style, ary_size)
        smallest_percent = smallest_percent_size(style, ary_size)

        if cfg['EnforcedStyle'] == style.to_s
          # do nothing
        elsif cfg['EnforcedStyle'].nil?
          cfg['EnforcedStyle'] = style.to_s
        elsif smallest_percent <= largest_brackets
          self.config_to_allow_offenses = { 'Enabled' => false }
        else
          cfg['EnforcedStyle'] = 'percent'
          cfg['MinSize'] = largest_brackets + 1
        end
      end

      def largest_brackets_size(style, ary_size)
        # why `self.class.largest_brackets` instead of `@largest_brackets`?
        # see https://github.com/rubocop/rubocop/pull/3973/commits/2c5dbdd1db563f2dab4754738e139f9f20b7f8fc

        self.class.largest_brackets ||= -Float::INFINITY

        if style == :brackets && ary_size > self.class.largest_brackets
          self.class.largest_brackets = ary_size
        end

        self.class.largest_brackets
      end

      def smallest_percent_size(style, ary_size)
        @smallest_percent ||= Float::INFINITY

        @smallest_percent = ary_size if style == :percent && ary_size < @smallest_percent

        @smallest_percent
      end
    end
  end
end
