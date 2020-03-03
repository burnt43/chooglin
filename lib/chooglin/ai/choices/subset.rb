module Chooglin
  class Ai
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
    end
  end
end
