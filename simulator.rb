require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'digits'
require 'method-result-caching'
require 'ruby-lazy-const'

current_directory = Pathname.new( __FILE__).dirname
lib_directory = current_directory.join('lib')
LazyConst::Config.base_dir = current_directory.join('lib').to_s

player1 = Chooglin::Ai.new(
  name: 'Player 1',
  subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.take_max_points,
  keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
    points_to_quit_on_one: 0
  ),
  steal_proc: Chooglin::Ai::Choices::Steal.always_attempt_steal
)

player2 = Chooglin::Ai.new(
  name: 'Player 2',
  subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.take_max_points,
  keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
    points_to_quit_on_one: 0
  ),
  steal_proc: Chooglin::Ai::Choices::Steal.always_attempt_steal
)

player3 = Chooglin::Ai.new(
  name: 'Player 3',
  subset_to_take_on_roll: Chooglin::Ai::Choices::Subset.take_max_points,
  keep_rolling: Chooglin::Ai::Choices::RollOrQuit.continue_by_points_per_dice_remaining(
    points_to_quit_on_one: 0
  ),
  steal_proc: Chooglin::Ai::Choices::Steal.always_attempt_steal
)

Chooglin.debug = true
Chooglin::GameSimulator.new(
  player1,
  player2,
  player3
).run
