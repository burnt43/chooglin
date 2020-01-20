require 'set'

module Kernel
  def jcarson_debug(msg)
    puts "\033[0;32m#{msg}\033[0;0m"
  end
end

# TODO: take this out into its own gem
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
      results = {}

      (1..6).each do |n|
        rolls = []

        each_digit_combo(n, base: 6, offset: 1) do |*raw_values|
          rolls.push(Roll.initialize_from_raw_values(*raw_values))
        end

        rolls.each do |roll|
          (results[n] ||= {})[roll.score] ||= 0
          results[n][roll.score] += 1
        end
      end

      results.each do |number_of_dice, score_histogram|
        total = score_histogram.values.reduce(:+)
        puts '-'*50
        puts "Number of Dice: #{number_of_dice}"
        puts "Total Permutations: #{total}"

        score_histogram.keys.sort.each do |score|
          if score == 0
            printf("%10s %15.8f%%\n", score.to_s, 100 * (score_histogram[score] / total.to_f))
          else
            count_at_least_score =
              score_histogram.reduce(0) do |acc, histogram_pair|
                reduce_score = histogram_pair[0]
                reduce_count = histogram_pair[1]

                acc += (reduce_score >= score ? reduce_count : 0)
              end

            printf("%10s %15.8f%%\n", ">=#{score}", 100 * (count_at_least_score / total.to_f))
          end
        end
      end
    end
  end

  class Roll
    class TypeResult
      attr_reader :remaining_roll
      attr_reader :score

      def initialize(passed, remaining_roll=false, score=0)
        @passed = passed
        @score = score
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
      @score ||=
        if size == 1 || size == 2
          score_by_single_dice
        else
          result = nil

          %i[
            one_of_each
            three_pair
            hex_sixes
            hex_fives
            hex_fours
            hex_threes
            hex_twos
            hex_ones
            penta_sixes
            penta_fives
            penta_fours
            penta_threes
            penta_twos
            penta_ones
            quad_sixes
            quad_fives
            quad_fours
            quad_threes
            quad_twos
            quad_ones
            triple_sixes
            triple_fives
            triple_fours
            triple_threes
            triple_twos
            triple_ones
          ].each do |method_name|
            result = send(method_name)

            if result.passed?
              # jcarson_debug method_name
              break
            end
          end

          if result&.passed?
            # jcarson_debug result.remaining_roll
            result.score + (result.remaining_roll&.score || 0)
          else
            score_by_single_dice
          end
        end
    end

    def score_by_single_dice
      @dice_values.map(&:score).reduce(:+)
    end

    # REVIEW: probably some meta programming can be done here to
    # keep this short, but this does have the advantage of being
    # more readadble.
    def triple_ones;   group_of(3, 1) end
    def triple_twos;   group_of(3, 2) end
    def triple_threes; group_of(3, 3) end
    def triple_fours;  group_of(3, 4) end
    def triple_fives;  group_of(3, 5) end
    def triple_sixes;  group_of(3, 6) end
    def quad_ones;     group_of(4, 1) end
    def quad_twos;     group_of(4, 2) end
    def quad_threes;   group_of(4, 3) end
    def quad_fours;    group_of(4, 4) end
    def quad_fives;    group_of(4, 5) end
    def quad_sixes;    group_of(4, 6) end
    def penta_ones;    group_of(5, 1) end
    def penta_twos;    group_of(5, 2) end
    def penta_threes;  group_of(5, 3) end
    def penta_fours;   group_of(5, 4) end
    def penta_fives;   group_of(5, 5) end
    def penta_sixes;   group_of(5, 6) end
    def hex_ones;      group_of(6, 1) end
    def hex_twos;      group_of(6, 2) end
    def hex_threes;    group_of(6, 3) end
    def hex_fours;     group_of(6, 4) end
    def hex_fives;     group_of(6, 5) end
    def hex_sixes;     group_of(6, 6) end

    def three_pair
      condition_result =
        size == 6 &&
        sorted_raw_values[0] == sorted_raw_values[1] &&
        sorted_raw_values[1] != sorted_raw_values[2] &&
        sorted_raw_values[2] == sorted_raw_values[3] &&
        sorted_raw_values[3] != sorted_raw_values[4] &&
        sorted_raw_values[4] == sorted_raw_values[5]

      TypeResult.new(condition_result, nil, 1000)
    end

    def one_of_each
      condition_result = (size == 6 && sorted_raw_values == [1,2,3,4,5,6])

      TypeResult.new(condition_result, nil, 1500)
    end

    private

    def group_of(number_of, raw_dice_value)
      return TypeResult.new(false) unless size >= number_of

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
        score =
          (case raw_dice_value
           when 1 then 1000
           when 2 then 200
           when 3 then 300
           when 4 then 400
           when 5 then 500
           when 6 then 600
           else 0
           end) *
          (case number_of
           when 6 then 8
           when 5 then 4
           when 4 then 2
           when 3 then 1
           else 0
           end)

        if unused_dice_values.empty?
          TypeResult.new(true, nil, score)
        else
          TypeResult.new(true, Roll.new(*unused_dice_values), score)
        end
      else
        TypeResult.new(false)
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
