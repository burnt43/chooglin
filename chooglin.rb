require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'digits'
require 'method-result-caching'

module Chooglin
  class << self
    def debug=(value)
      @debug = value
    end

    def debug?
      !!@debug
    end

    def bust_survive_hotdice_probs
      1.upto(6) do |num_dice|
        printf("-----------------\nNumber of Dice: %d\n", num_dice)

        rolls = Roll.all(num_dice)

        ways_to_bust     = 0
        ways_to_survive  = 0
        ways_to_hot_dice = 0

        rolls.each do |roll|
          ways_to_bust +=1 if roll.bust?
          ways_to_survive +=1 if roll.survive?
          ways_to_hot_dice +=1 if roll.hot_dice?
        end

        printf("%20s: %2.2f%%\n", 'Bust', 100 * ways_to_bust / rolls.size.to_f)
        printf("%20s: %2.2f%%\n", 'Survive', 100 * ways_to_survive / rolls.size.to_f)
        printf("%20s: %2.2f%%\n", 'Hot Dice', 100 * ways_to_hot_dice / rolls.size.to_f)
      end
    end
  end

  class Roll
    # class methods
    class << self
      def random(num_dice)
        raise ArgumentError.new('invalid amount of dice') unless (1..6).include?(num_dice)

        dice_values = num_dice.times.map { Random.rand(6) + 1 }
        self.new(*dice_values)
      end

      def all(*number_of_dice_values)
        adjusted_values =
          if number_of_dice_values.empty?
            [1, 2, 3, 4, 5, 6]
          else
            number_of_dice_values
          end

        adjusted_values.each_with_object([]) do |num_digits, array|
          Digits::Generator.each_digit_combo(num_digits, base: 6, offset: 1) do |*digit_values|
            array.push( Roll.new(*digit_values) )
          end
        end
      end
    end

    def initialize(*dice_values)
      raise ArgumentError.new('invalid amount of dice') unless (1..6).include?(dice_values.size)

      @dice_values = dice_values
    end

    # instance methods
    def size
      @dice_values.size
    end

    def bust?
      subsets.select(&:valid_for_scoring?).size == 0
    end

    def survive?
      subsets.select(&:valid_for_scoring?).any? {|subset| subset.scored?}
    end

    def hot_dice?
      subsets.select(&:valid_for_scoring?).any? {|subset| subset.size == size}
    end

    def subsets
      size.downto(1).flat_map do |subset_size|
        @dice_values.combination(subset_size).map do |dice_combo|
          Subset.new(*dice_combo)
        end
      end
    end
    cache_result_for :subsets

    def valid_subsets
      subsets.select(&:valid_for_scoring?)
    end
    cache_result_for :valid_subsets

    def to_s
      "<##{self.class.name} @dice_values=#{@dice_values.to_s}>"
    end

    class Subset
      STATES = %i[
        earned_undefended
        earned_defended
        earned_stolen
        unearned_stolen
        lost_busted
        lost_stolen
      ]

      # class methods
      def initialize(*dice_values)
        @dice_values = dice_values
        @state = nil
      end

      # instance methods
      def size
        @dice_values.size
      end

      def has_state?
        !@state.nil?
      end

      STATES.each do |state_name|
        define_method "mark_state_#{state_name}!" do
          @state = state_name
        end
      end

      def valid_for_scoring?
        !scores.empty? &&
        scores.map(&:points).reduce(:+) > 0
        size == num_scoring_dice
      end

      def num_scoring_dice
        scores.map(&:num_dice_needed).reduce(:+)
      end

      def points
        scores.map(&:points).reduce(:+)
      end
      cache_result_for :points

      def points_per_dice
        points / size.to_f
      end
      cache_result_for :points_per_dice

      def scored?
        !scores.empty?
      end

      def scores
        values     = @dice_values.clone
        check_size = values.size
        result     = []

        while !values.empty?
          # puts "#{check_size}:#{values.to_s}"
          case check_size
          when 6
            sorted_values = values.sort

            if values.select{|x| x == 1}.size == 6
              result.push(Score.new(:six_ones))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 6
              result.push(Score.new(:six_sixes))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 6
              result.push(Score.new(:six_fives))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 6
              result.push(Score.new(:six_fours))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 6
              result.push(Score.new(:six_threes))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 6
              result.push(Score.new(:six_twos))
              values.clear
              check_size = values.size
            elsif sorted_values == [1, 2, 3, 4, 5, 6]
              result.push(Score.new(:unique))
              values.clear
              check_size = values.size
            elsif (sorted_values[0] == sorted_values[1]) &&
                  (sorted_values[2] == sorted_values[3]) &&
                  (sorted_values[4] == sorted_values[5]) &&
                  (sorted_values[1] != sorted_values[2]) &&
                  (sorted_values[3] != sorted_values[4])
              result.push(Score.new(:three_pair))
              values.clear
              check_size = values.size
            else
              check_size = 5
            end
          when 5
            if values.select{|x| x == 1}.size == 5
              result.push(Score.new(:five_ones))
              values.reject!{|x| x == 1}
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 5
              result.push(Score.new(:five_sixes))
              values.reject!{|x| x == 6}
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 5
              result.push(Score.new(:five_fives))
              values.reject!{|x| x == 5}
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 5
              result.push(Score.new(:five_fours))
              values.reject!{|x| x == 4}
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 5
              result.push(Score.new(:five_threes))
              values.reject!{|x| x == 3}
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 5
              result.push(Score.new(:five_twos))
              values.reject!{|x| x == 2}
              check_size = values.size
            else
              check_size = 4
            end
          when 4
            if values.select{|x| x == 1}.size == 4
              result.push(Score.new(:four_ones))
              values.reject!{|x| x == 1}
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 4
              result.push(Score.new(:four_sixes))
              values.reject!{|x| x == 6}
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 4
              result.push(Score.new(:four_fives))
              values.reject!{|x| x == 5}
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 4
              result.push(Score.new(:four_fours))
              values.reject!{|x| x == 4}
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 4
              result.push(Score.new(:four_threes))
              values.reject!{|x| x == 3}
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 4
              result.push(Score.new(:four_twos))
              values.reject!{|x| x == 2}
              check_size = values.size
            else
              check_size = 3
            end
          when 3
            if values.select{|x| x == 1}.size == 3
              result.push(Score.new(:three_ones))
              values.reject!{|x| x == 1}
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 3
              result.push(Score.new(:three_sixes))
              values.reject!{|x| x == 6}
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 3
              result.push(Score.new(:three_fives))
              values.reject!{|x| x == 5}
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 3
              result.push(Score.new(:three_fours))
              values.reject!{|x| x == 4}
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 3
              result.push(Score.new(:three_threes))
              values.reject!{|x| x == 3}
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 3
              result.push(Score.new(:three_twos))
              values.reject!{|x| x == 2}
              check_size = values.size
            else
              check_size = 2
            end
          when 2
            check_size = 1
          when 1
            while (value_index = values.find_index{|x| x == 1 || x == 5})
              value = values[value_index]
              case value
              when 1
                result.push(Score.new(:single_one))
              when 5
                result.push(Score.new(:single_five))
              end

              values.delete_at(value_index)
            end

            values.clear
          end
        end

        result
      end
      cache_result_for :scores

      def to_s
        "<##{self.class.name} @dice_values=#{@dice_values.to_s} @state=#{@state}>"
      end
    end

    class Score
      # class methods
      def initialize(type)
        @type = type
      end

      # instance methods
      def points
        case @type
        when :six_ones     then 1000 * 8
        when :six_twos     then 200 * 8
        when :six_threes   then 300 * 8
        when :six_fours    then 400 * 8
        when :six_fives    then 500 * 8
        when :six_sixes    then 600 * 8
        when :unique       then 1500
        when :three_pair   then 1000
        when :five_ones    then 1000 * 4
        when :five_twos    then 200 * 4
        when :five_threes  then 300 * 4
        when :five_fours   then 400 * 4
        when :five_fives   then 500 * 4
        when :five_sixes   then 600 * 4
        when :four_ones    then 1000 * 2
        when :four_twos    then 200 * 2
        when :four_threes  then 300 * 2
        when :four_fours   then 400 * 2
        when :four_fives   then 500 * 2
        when :four_sixes   then 600 * 2
        when :three_ones   then 1000
        when :three_twos   then 200
        when :three_threes then 300
        when :three_fours  then 400
        when :three_fives  then 500
        when :three_sixes  then 600
        when :single_one   then 100
        when :single_five  then 50
        else
          0
        end
      end

      def num_dice_needed
        case @type
        when :six_ones     then 6
        when :six_twos     then 6
        when :six_threes   then 6
        when :six_fours    then 6
        when :six_fives    then 6
        when :six_sixes    then 6
        when :unique       then 6
        when :three_pair   then 6
        when :five_ones    then 5
        when :five_twos    then 5
        when :five_threes  then 5
        when :five_fours   then 5
        when :five_fives   then 5
        when :five_sixes   then 5
        when :four_ones    then 4
        when :four_twos    then 4
        when :four_threes  then 4
        when :four_fours   then 4
        when :four_fives   then 4
        when :four_sixes   then 4
        when :three_ones   then 3
        when :three_twos   then 3
        when :three_threes then 3
        when :three_fours  then 3
        when :three_fives  then 3
        when :three_sixes  then 3
        when :single_one   then 1
        when :single_five  then 1
        else
          0
        end
      end

      def to_s
        "<##{self.class.name} @type=#{@type}>"
      end
    end
  end

  class Pot
    attr_reader :subsets

    # class methods
    def initialize(subsets=[])
      @subsets = subsets
    end

    # instance methods
    def add_subset(subset)
      @subsets.push(subset)
    end

    def points
      @subsets.map(&:points).reduce(:+) || 0
    end

    def total_dice_used
      @subsets.map(&:size).reduce(:+) || 0
    end

    def dice_remaining
      6 - (total_dice_used % 6)
    end

    def unmarked_subsets
      @subsets.reject {|s| s.has_state?}
    end

    def mark_unmarked_subsets_as(state)
      unmarked_subsets.each {|s| s.send("mark_state_#{state}!")}
    end

    # TODO: method for mark unearned_stolen as earned_stolen 

    alias_method :old_clone, :clone
    def clone
      self.class.new(subsets.map(&:clone))
    end

    def to_s
      "<##{self.class.name} points=#{points}>"
    end
  end

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

    # TODO: this must return a result. the result has the pot, but also how the turn ended (quit, bust, failed steal)
    # TODO: Track points accumualted, points stolen, points earned.
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

          active_pot = Pot.new
        end
      else
        active_pot = Pot.new
      end

      dice_remaining = active_pot.dice_remaining

      loop do
        puts "\033[0;34mROLLING\033[0;0m (with #{dice_remaining} dice at #{active_pot.points} points)" if Chooglin.debug?

        roll = Roll.random(dice_remaining)
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

    module Choices
      module Subset
        class << self
          def take_max_points
            lambda do |roll, current_points|
              roll.valid_subsets.max {|subset_a, subset_b| subset_a.points <=> subset_b.points}
            end
          end

          def take_min_points_and_min_dice
            lambda do |roll, current_points|
              roll.valid_subsets.min do |subset_a, subset_b|
                comp = subset_a.points <=> subset_b.points
                comp == 0 ? subset_a.size <=> subset_b.size : comp
              end
            end
          end

          def take_min_points_and_max_dice
            lambda do |roll, current_points|
              roll.valid_subsets.min do |subset_a, subset_b|
                comp = subset_a.points <=> subset_b.points
                comp == 0 ? subset_b.size <=> subset_a.size : comp
              end
            end
          end

          def take_min_dice_and_max_points
            lambda do |roll, current_points|
              roll.valid_subsets.min do |subset_a, subset_b|
                comp = subset_a.size <=> subset_b.size
                comp == 0 ? subset_b.points <=> subset_a.points : comp
              end
            end
          end

          def take_min_dice_and_max_points_per_dice
            lambda do |roll, current_points|
              roll.valid_subsets.min do |subset_a, subset_b|
                comp = subset_a.size <=> subset_b.size
                comp == 0 ? subset_b.points_per_dice <=> subset_a.points_per_dice : comp
              end
            end
          end

          def take_max_points_per_dice_and_max_dice
            lambda do |roll, current_points|
              roll.valid_subsets.max do |subset_a, subset_b|
                comp = subset_a.points_per_dice <=> subset_b.points_per_dice
                if comp == 0
                  subset_a.size <=> subset_b.size
                else
                  comp
                end
              end
            end
          end

          def take_max_points_per_dice_and_min_dice
            lambda do |roll, current_points|
              roll.valid_subsets.max do |subset_a, subset_b|
                comp = subset_a.points_per_dice <=> subset_b.points_per_dice
                comp == 0 ? subset_b.size <=> subset_a.size : comp
              end
            end
          end
        end
      end

      module RollOrQuit
        class << self
          def continue_by_points_per_dice_remaining(
            points_to_quit_on_five:  Float::INFINITY,
            points_to_quit_on_four:  Float::INFINITY,
            points_to_quit_on_three: Float::INFINITY,
            points_to_quit_on_two:   Float::INFINITY,
            points_to_quit_on_one:   Float::INFINITY
          )
            lambda do |roll, subset, current_points|
              dice_remaining = roll.size - subset.size

              case dice_remaining
              when 5 then current_points < points_to_quit_on_five
              when 4 then current_points < points_to_quit_on_four
              when 3 then current_points < points_to_quit_on_three
              when 2 then current_points < points_to_quit_on_two
              when 1 then current_points < points_to_quit_on_one
              else
                true
              end
            end
          end
        end
      end

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

player1 = Chooglin::Ai.new(
  name: 'Player 1',
  subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.take_max_points,
  keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
    points_to_quit_on_one: 0
  ),
  steal_proc: Chooglin::Ai::Choices::Steal.always_attempt_steal
)

player2 = Chooglin::Ai.new(
  name: 'Player 2',
  subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.take_max_points,
  keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
    points_to_quit_on_one: 0
  ),
  steal_proc: Chooglin::Ai::Choices::Steal.always_attempt_steal
)

player3 = Chooglin::Ai.new(
  name: 'Player 3',
  subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.take_max_points,
  keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
    points_to_quit_on_one: 0
  ),
  steal_proc: Chooglin::Ai::Choices::Steal.always_attempt_steal
)

Chooglin.debug = true
Chooglin::GameSimulator.new(
  player1,
  player2,
  player3
).run
