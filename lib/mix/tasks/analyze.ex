defmodule Mix.Tasks.Analyze do
  use Mix.Task

  @analytics_file "tmp/distribution.jsonl"

  def run([input_words_string]) do
    input_words = String.split(input_words_string, ",")

    word_lengths = input_words |> Enum.map(&byte_size/1) |> Enum.uniq()

    if Enum.count(word_lengths) > 1 do
      raise "not all words are the same length"
    end

    stitch_files_together(@analytics_file)

    existing_words =
      @analytics_file
      |> word_analytics()
      |> Enum.map(&Map.keys/1)
      |> List.flatten()
      |> MapSet.new()

    input_words
    |> MapSet.new()
    |> MapSet.difference(existing_words)
    |> Enum.into([])
    |> calculate_analytics(@analytics_file)

    stitch_files_together(@analytics_file)
    analyze(@analytics_file)
  end

  defp calculate_analytics([], _analytics_file), do: :ok

  defp calculate_analytics(input_words = [first_word | _], analytics_file) do
    IO.puts "Running analytics on #{inspect(input_words)}"
    length = byte_size(first_word)

    word_list = WordList.get(Application.get_env(:wordle_solver, :word_list_url), length)
    letter_distribution = LetterDistribution.build(word_list)

    sorted_list =
      word_list
      |> Enum.sort_by(fn word -> LetterDistribution.rank_word(letter_distribution, word) end)
      |> Enum.reverse()

    1..Enum.count(input_words)
    |> Enum.zip(input_words)
    |> Enum.map(fn {i, start_word} ->
      Task.async(fn ->
        IO.puts("write distribution for #{start_word} (Thread #{i})")

        distribution =
          Enum.map(word_list, fn target_word ->
            {target_word, WordleSolver.quick_solve(target_word, start_word, sorted_list)}
          end)
          |> Enum.into(%{})

        row = %{start_word => distribution} |> Jason.encode!()

        {:ok, file} = File.open("#{analytics_file}.#{i}", [:append])
        IO.binwrite(file, "#{row}\n")
        File.close(file)
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
  end

  defp stitch_files_together(analytics_file) do
    {:ok, file} = File.open(analytics_file, [:write])

    "#{analytics_file}.*"
    |> Path.wildcard()
    |> Enum.each(fn thread_file ->
      content = File.read!(thread_file)
      IO.binwrite(file, content)
    end)

    File.close(file)

    IO.puts(analytics_file)
  end

  defp word_analytics(analytics_file) do
    File.read!(analytics_file)
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&Jason.decode!/1)
  end

  defp analyze(analytics_file) do
    word_analytics = word_analytics(analytics_file)

    average_guess_scores =
      word_analytics
      |> Enum.map(fn word_data ->
        [word] = Map.keys(word_data)
        guesses = word_data |> Map.values() |> List.first() |> Map.values()

        {word, Enum.sum(guesses) / Enum.count(guesses)}
      end)
      |> Enum.sort_by(fn {_word, score} -> score end)

    IO.puts("===== average guess scores")

    Enum.each(average_guess_scores, fn {word, score} ->
      IO.puts("#{word}: #{score}")
    end)

    over_six_guesses =
      word_analytics
      |> Enum.map(fn word_data ->
        [word] = Map.keys(word_data)
        guesses = word_data |> Map.values() |> List.first() |> Map.values()
        over_six = Enum.filter(guesses, fn guess -> guess > 6 end)

        total_count = Enum.count(guesses)
        over_six_count = Enum.count(over_six)

        {word, over_six_count, over_six_count / total_count}
      end)
      |> Enum.sort_by(fn {_word, _score, relative} -> relative end)

    IO.puts("===== over six guesses")

    Enum.each(over_six_guesses, fn {word, count, relative} ->
      IO.puts("#{word}: #{count} (#{Float.round(relative * 100, 4)}%)")
    end)

    IO.puts("=====")
  end
end
