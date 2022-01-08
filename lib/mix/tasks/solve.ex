defmodule Mix.Tasks.Solve do
  use Mix.Task

  @word_list_url "https://raw.githubusercontent.com/jesstess/Scrabble/master/scrabble/sowpods.txt"

  def run(args) do
    [target_word, start_word] = args

    word_list = WordList.get(@word_list_url, String.length(target_word))

    attempts = WordleSolver.solve(target_word, start_word, word_list)

    IO.puts("Solved in #{attempts} attempts")
  end
end
