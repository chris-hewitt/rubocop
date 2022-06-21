# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions to AST::ArrayNode
    module ArrayNode
      def contains_only?(child_type)
        children.all? do |value|
          value.type == child_type
        end
      end

      AST::ArrayNode.include self
    end
  end
end
