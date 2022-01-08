defmodule LetterDistribution do
  def build(word_list) do
    word_list
    |> Enum.map(&String.graphemes/1)
    |> Enum.reduce(%{}, &tally/2)
  end

  def rank_word(letter_distribution, word) do
    letters = String.graphemes(word)

    uniq_letters = letters |> Enum.uniq() |> Enum.count()

    rank =
      letters
      |> Enum.map(fn letter -> letter_distribution[letter] || 0 end)
      |> Enum.sum()

    {uniq_letters, rank, word}
  end

  defp tally(letters, tally) do
    Enum.reduce(
      letters,
      tally,
      fn letter, t ->
        Map.merge(t, %{letter => 1}, fn _k, v1, v2 -> v1 + v2 end)
      end
    )
  end
end
