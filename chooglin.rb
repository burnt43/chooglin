require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'digits'
require 'method-result-caching'

module Chooglin
  class << self
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

  class Ai
    attr_reader :subset_to_take_on_roll, :keep_rolling

    def initialize(subset_to_take_on_roll:, keep_rolling:)
      @subset_to_take_on_roll = subset_to_take_on_roll
      @keep_rolling = keep_rolling
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
        puts '-'*50 if @debug

        score_for_turn = 0
        number_of_dice = 6

        loop do
          roll = Roll.random(number_of_dice)
          puts roll if @debug

          chosen_subset = @ai.subset_to_take_on_roll.call(roll, @total_points)

          if chosen_subset.nil?
            puts "\033[0;33mBUSTED\033[0;0m (lost #{score_for_turn} points)" if @debug
            score_for_turn = 0
            break
          end

          score_for_turn += chosen_subset.points
          puts chosen_subset if @debug

          number_of_dice = roll.size - chosen_subset.size

          if number_of_dice > 0 && !@ai.keep_rolling.call(roll, chosen_subset, score_for_turn)
            puts "\033[0;32mQUITTING\033[0;0m (with #{score_for_turn} points)" if @debug
            break
          elsif number_of_dice == 0
            puts "\033[0;31mHOT DICE\033[0;0m (with #{score_for_turn} points)" if @debug
            number_of_dice = 6
          else
            puts "\033[0;34mROLLING\033[0;0m (with #{number_of_dice} dice at #{score_for_turn} points)" if @debug
          end
        end

        @total_points += score_for_turn
      end

      @total_points / @num_sims.to_f
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

    #
    class Subset
      # class methods
      def initialize(*dice_values)
        @dice_values = dice_values
      end

      # instance methods
      def size
        @dice_values.size
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
        "<##{self.class.name} @dice_values=#{@dice_values.to_s}>"
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
end

%w[
  take_max_points
  take_min_points_and_min_dice
  take_min_points_and_max_dice
  take_max_points_per_dice_and_max_dice
  take_max_points_per_dice_and_min_dice
  take_min_dice_and_max_points
  take_min_dice_and_max_points_per_dice
].each do |method_name|
  bot = Chooglin::Ai.new(
    subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.send(method_name),
#     keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
#       points_to_quit_on_one: 0
#     )
    keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
      points_to_quit_on_two: 2000,
      points_to_quit_on_one: 1500
    )
  )
  sim = Chooglin::PointAccumulatorSimulation.new(bot, 10_000, debug: false)
  result = sim.run
  printf("%-50s %-50s %.2f\n", method_name, "Average Score", result)
end
