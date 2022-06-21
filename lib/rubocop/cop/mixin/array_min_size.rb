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

      def determine_array_style_config_based_on_array_size(style, array_size)
        largest_brackets = largest_brackets_size(style, array_size)
        smallest_percent = smallest_percent_size(style, array_size)

        if smallest_percent <= largest_brackets
          self.config_to_allow_offenses = { 'Enabled' => false }
        else
          config_to_allow_offenses['EnforcedStyle'] = 'percent'
          config_to_allow_offenses['MinSize'] = largest_brackets + 1
        end
      end

      # def array_style_detected(style, ary_size) # rubocop:todo Metrics/AbcSize
      #   cfg = config_to_allow_offenses
      #   return if cfg['Enabled'] == false

      #   largest_brackets = largest_brackets_size(style, ary_size)
      #   smallest_percent = smallest_percent_size(style, ary_size)

      #   if cfg['EnforcedStyle'] == style.to_s
      #     # do nothing
      #   elsif cfg['EnforcedStyle'].nil?
      #     cfg['EnforcedStyle'] = style.to_s
      #   elsif smallest_percent <= largest_brackets
      #     self.config_to_allow_offenses = { 'Enabled' => false }
      #   else
      #     cfg['EnforcedStyle'] = 'percent'
      #     cfg['MinSize'] = largest_brackets + 1
      #   end
      # end

      def largest_brackets_size(style, array_size)
        # why `self.class.largest_brackets` instead of `@largest_brackets`?
        # see https://github.com/rubocop/rubocop/pull/3973/commits/2c5dbdd1db563f2dab4754738e139f9f20b7f8fc

        self.class.largest_brackets ||= -Float::INFINITY

        if style == :brackets && array_size > self.class.largest_brackets
          self.class.largest_brackets = array_size
        end

        self.class.largest_brackets
      end

      def smallest_percent_size(style, array_size)
        @smallest_percent ||= Float::INFINITY

        if style == :percent && array_size < @smallest_percent
          @smallest_percent = array_size
        end

        @smallest_percent
      end
    end
  end
end
