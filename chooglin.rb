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

# 10.times do
#   puts Chooglin::Roll.random(6)
# end

# tab = "  "
# roll = Chooglin::Roll.new(1,2,3,4,5,6)
# puts roll.to_s
# roll.subsets.select(&:valid_for_scoring?).each do |subset|
#   puts "#{tab}#{subset.to_s}"
#   subset.scores.each do |score|
#     puts "#{tab*2}#{score.to_s} #{score.points}"
#   end
# end

Chooglin.bust_survive_hotdice_probs

# Chooglin::Roll.all(4).each do |roll|
#   puts roll
# end
