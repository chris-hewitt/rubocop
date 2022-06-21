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
    end
  end
end
