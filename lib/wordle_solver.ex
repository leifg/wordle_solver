defmodule WordleSolver do
  def solve(target, seed, _word_list) when byte_size(target) != byte_size(seed) do
    raise "Target and start words need to have the same length"
  end

  def solve(target, seed, word_list) do
    validate_in_list(word_list, target, "target")
    validate_in_list(word_list, seed, "seed")

    letter_distribution = LetterDistribution.build(word_list)

    sorted_list =
      word_list
      |> Enum.sort_by(fn word -> LetterDistribution.rank_word(letter_distribution, word) end)
      |> Enum.reverse()

    num_of_attempts = iterate(sorted_list, seed, target, 1)

    if num_of_attempts < 0 do
      IO.puts("Couldn't find #{target} from #{seed}")
    end

    num_of_attempts
  end

  def quick_solve(target, seed, word_list) do
    iterate(word_list, seed, target, 1)
  end

  defp validate_in_list(word_list, word, name) do
    unless Enum.member?(word_list, word) do
      raise "#{name} word '#{word}' not in list"
    end
  end

  defp iterate([], input, target, attempt) do
    IO.puts("Nothing found after #{attempt} attempts (Input: #{input}, Target: #{target})")

    -1
  end

  defp iterate(_word_list, target, target, attempt), do: attempt

  defp iterate(word_list, input, target, attempt) do
    filtered_list =
      input
      |> Filter.build(target)
      |> Filter.apply(word_list)

    next_word = next_word(filtered_list)

    iterate(filtered_list, next_word, target, attempt + 1)
  end

  defp next_word(list) do
    word = List.first(list)
    word
  end
end
