# frozen_string_literal: true

module Pragma
  module Operation
    module Macro
      def self.Decorator(name: :instance)
        step = ->(input, options) { Decorator.for(input, name, options) }
        [step, name: "decorator.#{name}"]
      end

      module Decorator
        class << self
          def for(_input, name, options)
            return false unless validate_params(options)

            options["result.decorator.#{name}"] = options["decorator.#{name}.class"].new(
              options['model']
            )

            validate_expansion(options, name)
          end

          private

          def validate_params(options)
            options['contract.expand'] = Dry::Validation.Schema do
              optional(:expand) do
                if options['expand.disable']
                  none? | empty?
                else
                  array? do
                    each(:str?) &
                      # This is the ugliest, only way I found to define a dynamic validation tree.
                      (options['expand.limit'] ? max_size?(options['expand.limit']) : array?)
                  end
                end
              end
            end

            options['result.contract.expand'] = options['contract.expand'].call(options['params'])

            if options['result.contract.expand'].errors.any?
              options['result.response'] = Response::UnprocessableEntity.new(
                errors: options['result.contract.expand'].errors
              ).decorate_with(Pragma::Decorator::Error)

              return false
            end

            true
          end

          def validate_expansion(options, name)
            return true unless options["result.decorator.#{name}"].respond_to?(:validate_expansion)
            options["result.decorator.#{name}"].validate_expansion(options['params'][:expand])
            true
          rescue Pragma::Decorator::Association::ExpansionError => e
            options['result.response'] = Response::BadRequest.new(
              entity: Pragma::Operation::Error.new(
                error_type: :expansion_error,
                error_message: e.message
              )
            ).decorate_with(Pragma::Decorator::Error)
            false
          end
        end
      end
    end
  end
end
