module Chooglin
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
  end
end
