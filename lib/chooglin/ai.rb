module Chooglin
  class Ai
    attr_reader :subset_to_take_on_roll, :keep_rolling, :steal_proc
    attr_reader :pots

    def initialize(name:, subset_to_take_on_roll:, keep_rolling:, steal_proc:)
      @name                   = name
      @subset_to_take_on_roll = subset_to_take_on_roll
      @keep_rolling           = keep_rolling
      @steal_proc             = steal_proc
      @pots                   = []
    end

    def to_s
      "<##{self.class.name} @name=#{@name}>"
    end

    def add_pot!(pot, state: nil)
      return unless pot

      pot_to_add =
        if state
          new_pot = pot.clone
          new_pot.mark_unmarked_subsets_as(state)
          new_pot
        else
          pot
        end

      @pots.push(pot_to_add)
    end

    # TODO: fix first subset after successfull steal is marked as unearned_stolen, but this should remain nil to be set later
    # TODO: this must return a result. the result has the pot, but also how the turn ended (quit, bust, failed steal)
    # TODO: Track points accumualted, points stolen, points earned. (this is being done by adding pots to ais)
    def take_turn(
      active_pot: nil,
      previous_player: nil
    )
      puts "--------------------\n#{self} #{__method__}" if Chooglin.debug?

      steal_attempt = false
      previous_player_debug_name = previous_player&.to_s || 'previous_player'

      if active_pot
        if steal_proc.call(active_pot)
          puts "\033[0;36mSTEAL ATTEMPT\033[0;0m (for #{active_pot.points} points)"
          steal_attempt = true
        else
          puts "\033[0;36mNO STEAL\033[0;0m (leaving behind #{active_pot.points} points for #{previous_player_debug_name})"

          previous_player&.add_pot!(active_pot, state: :earned_undefended)

          active_pot = Chooglin::Pot.new
        end
      else
        active_pot = Chooglin::Pot.new
      end

      dice_remaining = active_pot.dice_remaining

      loop do
        puts "\033[0;34mROLLING\033[0;0m (with #{dice_remaining} dice at #{active_pot.points} points)" if Chooglin.debug?

        roll = Chooglin::Roll.random(dice_remaining)
        puts roll if Chooglin.debug?

        chosen_subset = subset_to_take_on_roll.call(roll, @total_points)

        if chosen_subset.nil?
          if steal_attempt
            puts "\033[0;36mSTEAL FAILED\033[0;0m (#{active_pot.points} points awarded to #{previous_player_debug_name})" if Chooglin.debug?
            previous_player&.add_pot!(active_pot, state: :earned_defended)
            return nil
          else
            puts "\033[0;33mBUSTED\033[0;0m (lost #{active_pot.points} points)" if Chooglin.debug?
            add_pot!(active_pot, state: :lost_busted)
            return nil
          end
        end

        puts chosen_subset if Chooglin.debug?

        if steal_attempt
          puts "\033[0;36mSTEAL SUCCESSFUL\033[0;0m (#{active_pot.points} points from #{previous_player_debug_name})" if Chooglin.debug?
          previous_player&.add_pot!(active_pot, state: :lost_stolen)
          active_pot.add_subset(chosen_subset)
          active_pot.mark_unmarked_subsets_as(:unearned_stolen)
          steal_attempt = false
        else
          active_pot.add_subset(chosen_subset)
        end

        dice_remaining = roll.size - chosen_subset.size

        if dice_remaining > 0 && !keep_rolling.call(roll, chosen_subset, active_pot.points)
          puts "\033[0;32mQUITTING\033[0;0m (with #{active_pot.points} points at #{dice_remaining} dice remaining)" if Chooglin.debug?
          return active_pot
        elsif dice_remaining == 0
          puts "\033[0;31mHOT DICE\033[0;0m (with #{active_pot.points} points)" if Chooglin.debug?
          dice_remaining = 6
        end
      end
    end
  end
end
