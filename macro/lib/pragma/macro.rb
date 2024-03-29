# frozen_string_literal: true

require 'trailblazer-macro'

Zeitwerk::Loader.new.tap do |loader|
  loader.tag = File.basename(__FILE__, ".rb")
  loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
  loader.push_dir(File.expand_path('..', __dir__))
  loader.setup
end

module Pragma
  module Macro
    class Error < StandardError; end

    class << self
      # Returns a skill or raises a {#MissingSkillError}.
      #
      # @param macro [String] the name of the macro requiring the skill
      # @param skill [String] the name of the string
      # @param options [Hash] the +options+ hash of the operation
      #
      # @return [Object] the value of the skill
      #
      # @raise [MissingSkillError] if the skill is undefined or +nil+
      #
      # @private
      def require_skill(macro, skill, options)
        options[skill] || fail(MissingSkillError.new(macro, skill))
      end
    end

    # Error raised when a skill is required but not present.
    #
    # @private
    class MissingSkillError < Error
      # Initializes the error.
      #
      # @param macro [String] the macro requiring the skill
      # @param skill [String] the name of the missing skill
      def initialize(macro, skill)
        message = <<~ERROR
          You are attempting to use the #{macro} macro, but no `#{skill}' skill is defined.

          You can define the skill by adding the following to your operation:

            self['#{skill}'] = MyCustomClass

          If the skill holds a class, this can happen when the required class (e.g. the contract
          class) is not in the expected location. If that's the case, you can just move the class to
          the expected location and avoid defining the skill manually.
        ERROR

        super message
      end
    end
  end
end

module Pragma
  module Operation
    Macro = Pragma::Macro
  end
end
