# frozen_string_literal: true

module RuboCop
  module Cop
    # Common code for Style/SymbolArray and Style/WordArray cops
    module ArraySyntax
      private

      def bracketed_array_of?(element_type, node)
        node.square_brackets? && !node.values.empty? && node.contains_only?(element_type)
      end
    end
  end
end
