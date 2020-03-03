module Chooglin
  class PointAccumulatorSimulation
    def initialize(ai, num_sims, debug: true)
      @ai = ai
      @total_points = 0
      @num_sims = num_sims
      @debug = debug
    end

    def run
      @num_sims.times do
      end

      @total_points / @num_sims.to_f
    end
  end
end
