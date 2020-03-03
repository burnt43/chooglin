module Chooglin
  class Roll
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
              result.push(Chooglin::Roll::Score.new(:six_ones))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 6
              result.push(Chooglin::Roll::Score.new(:six_sixes))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 6
              result.push(Chooglin::Roll::Score.new(:six_fives))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 6
              result.push(Chooglin::Roll::Score.new(:six_fours))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 6
              result.push(Chooglin::Roll::Score.new(:six_threes))
              values.clear
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 6
              result.push(Chooglin::Roll::Score.new(:six_twos))
              values.clear
              check_size = values.size
            elsif sorted_values == [1, 2, 3, 4, 5, 6]
              result.push(Chooglin::Roll::Score.new(:unique))
              values.clear
              check_size = values.size
            elsif (sorted_values[0] == sorted_values[1]) &&
                  (sorted_values[2] == sorted_values[3]) &&
                  (sorted_values[4] == sorted_values[5]) &&
                  (sorted_values[1] != sorted_values[2]) &&
                  (sorted_values[3] != sorted_values[4])
              result.push(Chooglin::Roll::Score.new(:three_pair))
              values.clear
              check_size = values.size
            else
              check_size = 5
            end
          when 5
            if values.select{|x| x == 1}.size == 5
              result.push(Chooglin::Roll::Score.new(:five_ones))
              values.reject!{|x| x == 1}
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 5
              result.push(Chooglin::Roll::Score.new(:five_sixes))
              values.reject!{|x| x == 6}
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 5
              result.push(Chooglin::Roll::Score.new(:five_fives))
              values.reject!{|x| x == 5}
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 5
              result.push(Chooglin::Roll::Score.new(:five_fours))
              values.reject!{|x| x == 4}
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 5
              result.push(Chooglin::Roll::Score.new(:five_threes))
              values.reject!{|x| x == 3}
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 5
              result.push(Chooglin::Roll::Score.new(:five_twos))
              values.reject!{|x| x == 2}
              check_size = values.size
            else
              check_size = 4
            end
          when 4
            if values.select{|x| x == 1}.size == 4
              result.push(Chooglin::Roll::Score.new(:four_ones))
              values.reject!{|x| x == 1}
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 4
              result.push(Chooglin::Roll::Score.new(:four_sixes))
              values.reject!{|x| x == 6}
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 4
              result.push(Chooglin::Roll::Score.new(:four_fives))
              values.reject!{|x| x == 5}
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 4
              result.push(Chooglin::Roll::Score.new(:four_fours))
              values.reject!{|x| x == 4}
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 4
              result.push(Chooglin::Roll::Score.new(:four_threes))
              values.reject!{|x| x == 3}
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 4
              result.push(Chooglin::Roll::Score.new(:four_twos))
              values.reject!{|x| x == 2}
              check_size = values.size
            else
              check_size = 3
            end
          when 3
            if values.select{|x| x == 1}.size == 3
              result.push(Chooglin::Roll::Score.new(:three_ones))
              values.reject!{|x| x == 1}
              check_size = values.size
            elsif values.select{|x| x == 6}.size == 3
              result.push(Chooglin::Roll::Score.new(:three_sixes))
              values.reject!{|x| x == 6}
              check_size = values.size
            elsif values.select{|x| x == 5}.size == 3
              result.push(Chooglin::Roll::Score.new(:three_fives))
              values.reject!{|x| x == 5}
              check_size = values.size
            elsif values.select{|x| x == 4}.size == 3
              result.push(Chooglin::Roll::Score.new(:three_fours))
              values.reject!{|x| x == 4}
              check_size = values.size
            elsif values.select{|x| x == 3}.size == 3
              result.push(Chooglin::Roll::Score.new(:three_threes))
              values.reject!{|x| x == 3}
              check_size = values.size
            elsif values.select{|x| x == 2}.size == 3
              result.push(Chooglin::Roll::Score.new(:three_twos))
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
                result.push(Chooglin::Roll::Score.new(:single_one))
              when 5
                result.push(Chooglin::Roll::Score.new(:single_five))
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
  end
end
