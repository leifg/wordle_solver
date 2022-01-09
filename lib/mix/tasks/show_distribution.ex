defmodule Mix.Tasks.ShowDistribution do
  use Mix.Task

  @num_of_top_words 100

  def run([length_string]) do
    length = String.to_integer(length_string)

    IO.puts("letter distribution for #{length} letter words")

    word_list = WordList.get(Application.get_env(:wordle_solver, :word_list_url), length)
    letter_distribution = LetterDistribution.build(word_list)

    letter_distribution
    |> Enum.sort_by(fn {_k, v} -> -v end)
    |> IO.inspect(label: "letter distribution")

    word_list
    |> Enum.map(fn word -> LetterDistribution.rank_word(letter_distribution, word) end)
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.take(@num_of_top_words)
    |> IO.inspect(label: "highest ranking words", limit: :infinity)
  end
end
