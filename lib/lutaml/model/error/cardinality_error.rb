module Lutaml
  module Model
    class CardinalityError < Error
      def initialize(attribute_name, expected_count, actual_count)
        super("Value cardinality Error: attribute value of #{attribute_name} was expected to have #{expected_count} elements but had #{actual_count}")
      end
    end
  end
end
