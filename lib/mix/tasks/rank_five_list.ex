defmodule Mix.Tasks.RankFiveList do
  use Mix.Task

  @five_words [
    ["bemix", "clunk", "grypt", "vozhd", "waqfs"],
    ["blunk", "cimex", "grypt", "vozhd", "waqfs"],
    ["brung", "cylix", "kempt", "vozhd", "waqfs"],
    ["brung", "xylic", "kempt", "vozhd", "waqfs"],
    ["fjord", "gucks", "nymph", "vibex", "waltz"],
    ["chunk", "fjord", "gymps", "vibex", "waltz"],
    ["glent", "jumby", "prick", "vozhd", "waqfs"],
    ["clipt", "jumby", "kreng", "vozhd", "waqfs"],
    ["jumby", "pling", "treck", "vozhd", "waqfs"],
    ["bling", "jumpy", "treck", "vozhd", "waqfs"],
    ["brick", "glent", "jumpy", "vozhd", "waqfs"]
  ]

  @word_length 5

  def run([word_list_file]) do
    IO.puts("Find best five words #{word_list_file}")

    global_word_list =
      word_list_file
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(fn word -> String.length(word) == @word_length end)

    global_word_list |> Enum.count() |> IO.inspect(label: "Words to Evaluate")

    Enum.map(@five_words, fn word_list ->
      IO.puts("Evaluating #{inspect(word_list)}")

      remaining_words_count =
        Enum.map(global_word_list, fn target_word ->
          word_list
          |> Enum.reduce(global_word_list, fn best_word, filtered_list ->
            best_word
            |> Filter.build(target_word)
            |> Filter.apply(filtered_list)
          end)
          |> Enum.count()
        end)

      {word_list, remaining_words_count}
    end)
    |> Enum.each(fn {word_list, stats} ->
      IO.puts("=== #{Enum.join(word_list, ",")}")
      IO.puts("Average: #{average(stats)}")
      IO.puts("Min: #{Enum.min(stats)}")
      IO.puts("Max: #{Enum.max(stats)}")
      IO.puts("======")
    end)
  end

  defp average(scores) do
    sum = Enum.reduce(scores, fn score, sum -> sum + score end)
    sum / Enum.count(scores)
  end
end
