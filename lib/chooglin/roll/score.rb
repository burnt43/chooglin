module Chooglin
  class Roll
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
