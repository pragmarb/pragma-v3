# frozen_string_literal: true

module Pragma
  module Operation
    class Base
      def self.inherited(klass)
        klass.include Dry::Transaction
      end
    end
  end
end
