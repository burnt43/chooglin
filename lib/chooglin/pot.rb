module Chooglin
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
end
