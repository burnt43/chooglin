module Chooglin
  class Roll
    # class methods
    class << self
      def random(num_dice)
        raise ArgumentError.new('invalid amount of dice') unless (1..6).include?(num_dice)

        dice_values = num_dice.times.map { Random.rand(6) + 1 }
        self.new(*dice_values)
      end

      def all
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

    def num_scoring_dice
    end

    def all_scores
    end

    def hot_dice?
    end

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
      def to_s
        "<##{self.class.name} @type=#{@type}>"
      end
    end
  end
end

# 10.times do
#   puts Chooglin::Roll.random(6)
# end

puts Chooglin::Roll::Subset.new(2,2,3,3,2,3).scores
