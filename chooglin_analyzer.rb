require 'set'

def each_digit_combo(number_of_digits, base: 10, offset: 0)
  ruby_code = StringIO.new

  number_of_digits.times.map do |n|
    ruby_code.puts("(#{0+offset}..#{(base-1) + offset}).each do |digit_#{n}|")
  end

  ruby_code.print("yield(")
  ruby_code.print(
    number_of_digits.times.map{ |n| "digit_#{n}" }.join(',')
  )
  ruby_code.puts(")")

  number_of_digits.times do |n|
    ruby_code.puts("end")
  end

  ruby_code.string

  eval(ruby_code.string)
end

module Chooglin
  class << self
    def foo
      rolls = []

      each_digit_combo(3, base: 6, offset: 1) do |*raw_values|
        rolls.push(Roll.initialize_from_raw_values(*raw_values))
      end

      rolls.each do |roll|
        printf("%-40s %s\n", roll.to_s, roll.triple_ones?.passed?)
      end
    end
  end

  class Roll
    class TypeResult
      def initialize(passed, remaining_roll)
        @passed = passed
        @remaining_roll = remaining_roll
      end

      def passed?
        @passed
      end
    end

    class << self
      def initialize_from_raw_values(*raw_values)
        new(
          *(raw_values.map {|v| DiceValue.new(v)})
        )
      end
    end

    def initialize(*dice_values)
      @dice_values = dice_values
    end

    def to_s
      "#<#{self.class.name}: #{dice_values_as_string}>"
    end

    def dice_values_as_string
      @dice_values.map{|dv| dv.raw_value.to_s}.join('-')
    end

    def size
      @dice_values.size
    end

    def score
      case size
      when 3
      when 1,2
        @dice_values.map(&:score).reduce(:+)
      else
        0
      end
    end

    # REVIEW: probably some meta programming can be done here to
    # keep this short, but this does have the advantage of being
    # more readadble.
    def triple_ones?;   group_of?(3, 1) end
    def triple_twos?;   group_of?(3, 2) end
    def triple_threes?; group_of(3, 3) end
    def triple_fours?;  group_of(3, 4) end
    def triple_fives?;  group_of(3, 5) end
    def triple_sixes?;  group_of(3, 6) end
    def quad_ones?;     group_of(4, 1) end
    def quad_twos?;     group_of(4, 2) end
    def quad_threes?;   group_of(4, 3) end
    def quad_fours?;    group_of(4, 4) end
    def quad_fives?;    group_of(4, 5) end
    def quad_sixes?;    group_of(4, 6) end
    def penta_ones?;    group_of(5, 1) end
    def penta_twos?;    group_of(5, 2) end
    def penta_threes?;  group_of(5, 3) end
    def penta_fours?;   group_of(5, 4) end
    def penta_fives?;   group_of(5, 5) end
    def penta_sixes?;   group_of(5, 6) end
    def hex_ones?;      group_of(6, 1) end
    def hex_twos?;      group_of(6, 2) end
    def hex_threes?;    group_of(6, 3) end
    def hex_fours?;     group_of(6, 4) end
    def hex_fives?;     group_of(6, 5) end
    def hex_sixes?;     group_of(6, 6) end

    def three_pair?
      condition_result =
        sorted_raw_values[0] == sorted_raw_values[1] &&
        sorted_raw_values[1] != sorted_raw_values[2] &&
        sorted_raw_values[2] == sorted_raw_values[3] &&
        sorted_raw_values[3] != sorted_raw_values[4] &&
        sorted_raw_values[4] == sorted_raw_values[5]
    end

    def one_of_each?
      condition_result = sorted_raw_values == [1,2,3,4,5,6]
    end

    private

    def group_of?(number_of, raw_dice_value)
      number_found = 0
      unused_dice_values = []

      @dice_values.each do |dice_value|
        if dice_value.raw_value == raw_dice_value
          number_found += 1
        else
          unused_dice_values.push(dice_value)
        end
      end

      if number_found == number_of
        if unused_dice_values.empty?
          TypeResult.new(true, nil)
        else
          TypeResult.new(true, Roll.initialize_from_raw_values(*unused_dice_values))
        end
      else
        TypeResult.new(false, nil)
      end
    end

    def sorted_raw_values
      @sorted_raw_values ||= @dice_values.map(&:raw_value).sort
    end
  end

  class DiceValue
    attr_reader :raw_value

    def initialize(raw_value)
      @raw_value = raw_value
    end

    def score
      case @raw_value
      when 1 then 100
      when 5 then 50
      else 0
      end
    end
  end
end

Chooglin.foo
