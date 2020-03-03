module Chooglin
  class GameSimulator
    def initialize(*ais)
      raise ArgumentError.new('the game needs at least 3 players.') unless ais.size >= 3

      @ais = ais
      @current_ai_index = 0
    end

    def run
      active_pot  = nil
      current_ai  = nil
      previous_ai = nil

      3.times do
        current_ai = @ais[@current_ai_index]

        active_pot = current_ai.take_turn(
          active_pot: active_pot,
          previous_player: previous_ai
        )

        previous_ai = current_ai
        increment_current_ai_index
      end

      @ais.each do |ai|
        puts '-'*50
        puts ai
        ai.pots.each do |pot|
          puts pot
          pot.subsets.each do |subset|
            puts subset
          end
        end
      end
    end

    def increment_current_ai_index
      @current_ai_index = (@current_ai_index + 1) % @ais.size
    end
  end
end
