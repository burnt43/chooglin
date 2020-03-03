module Chooglin
  class Ai
    module Choices
      module Steal
        class << self
          def always_attempt_steal
            lambda do |active_pot|
              true
            end
          end
        end
      end
    end
  end
end
