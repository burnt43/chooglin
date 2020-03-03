module Chooglin
  class Ai
    module Choices
      module RollOrQuit
        class << self
          def continue_by_points_per_dice_remaining(
            points_to_quit_on_five:  Float::INFINITY,
            points_to_quit_on_four:  Float::INFINITY,
            points_to_quit_on_three: Float::INFINITY,
            points_to_quit_on_two:   Float::INFINITY,
            points_to_quit_on_one:   Float::INFINITY
          )
            lambda do |roll, subset, current_points|
              dice_remaining = roll.size - subset.size

              case dice_remaining
              when 5 then current_points < points_to_quit_on_five
              when 4 then current_points < points_to_quit_on_four
              when 3 then current_points < points_to_quit_on_three
              when 2 then current_points < points_to_quit_on_two
              when 1 then current_points < points_to_quit_on_one
              else
                true
              end
            end
          end
        end
      end
    end
  end
end
