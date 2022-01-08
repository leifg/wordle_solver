defmodule Mix.Tasks.Solve do
  use Mix.Task

  def run(args) do
    [target_word, start_word] = args

    WordleSolver.solve(target_word, start_word)
  end
end
