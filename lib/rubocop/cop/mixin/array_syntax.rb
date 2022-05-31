# frozen_string_literal: true

module RuboCop
  module Cop
    # Common code for ordinary arrays with [] that can be written with %
    # syntax.
    module ArraySyntax
      private

      def determine_array_style_config(style, array_size)
        if config_to_allow_offenses['Enabled'] == false
          # do nothing
        elsif config_to_allow_offenses['EnforcedStyle'] == style.to_s
          # do nothing
        elsif config_to_allow_offenses['EnforcedStyle'].nil?
          config_to_allow_offenses['EnforcedStyle'] = style.to_s
        else
          determine_array_style_config_based_on_array_size(style, array_size)
        end
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

      def largest_brackets_size(style, array_size)
        # why `self.class.largest_brackets` instead of `@largest_brackets`?
        # see https://github.com/rubocop/rubocop/pull/3973/commits/2c5dbdd1db563f2dab4754738e139f9f20b7f8fc

        if self.class.largest_brackets
        else
          self.class.largest_brackets = -Float::INFINITY
        end

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
