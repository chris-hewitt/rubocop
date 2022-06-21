# frozen_string_literal: true

module RuboCop
  module Cop
    # Common code for ordinary arrays with [] that can be written with %
    # syntax.
    module ArraySyntax
      private

      def bracketed_array_of?(element_type, node)
        node.square_brackets? && !node.values.empty? && node.contains_only?(element_type)
      end

      def determine_array_style_config(style, array_size)
        cfg = config_to_allow_offenses
        if cfg['Enabled'] == false
          # do nothing
        elsif cfg['EnforcedStyle'] == style.to_s
          # do nothing
        elsif cfg['EnforcedStyle'].nil?
          cfg['EnforcedStyle'] = style.to_s
        else
          determine_array_style_config_based_on_size(style, array_size)
        end
      end
    end
  end
end
