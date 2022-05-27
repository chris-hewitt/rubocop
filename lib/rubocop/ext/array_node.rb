# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions to AST::ArrayNode
    module ArrayNode
      def contains_only?(child_type)
        children.map(&:type).uniq == [child_type]
      end

      AST::ArrayNode.include self
    end
  end
end
