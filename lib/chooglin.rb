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
end
