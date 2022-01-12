defmodule Mix.Tasks.Analyze do
  use Mix.Task

  @defaults [
    file: "tmp/distribution.jsonl",
    threads: 10,
    length: 5,
    words: 10
  ]

  @options [
    file: :string,
    threads: :integer,
    length: :integer,
    words: :integer
  ]

  def run(args) do
    {arguments, [switch], []} =
      OptionParser.parse(args, strict: @options) |> IO.inspect(label: "parsed")

    arguments = @defaults |> Keyword.merge(arguments) |> Map.new() |> IO.inspect(label: "merged")

    {word_list, input_words} = calculate_input(switch, arguments)

    analytics_file = arguments[:file]

    stitch_files_together(analytics_file)

    existing_words =
      analytics_file
      |> word_analytics()
      |> Enum.map(&Map.keys/1)
      |> List.flatten()
      |> MapSet.new()

    input_words
    |> MapSet.new()
    |> MapSet.difference(existing_words)
    |> Enum.into([])
    |> calculate_analytics(analytics_file, word_list, arguments[:threads])

    stitch_files_together(analytics_file)
    analyze(analytics_file)
  end

  defp calculate_input("random", %{length: length, words: num_of_words}) do
    length = String.to_integer(length)
    num_of_words = String.to_integer(num_of_words)

    word_list = WordList.get(Application.get_env(:wordle_solver, :word_list_url), length)

    input_words =
      word_list
      |> Enum.shuffle()
      |> Enum.take(num_of_words)

    {word_list, input_words}
  end

  defp calculate_input("all", %{length: length}) do
    word_list = WordList.get(Application.get_env(:wordle_solver, :word_list_url), length)

    {word_list, word_list}
  end

  defp calculate_input(input_words_string, _) do
    input_words = String.split(input_words_string, ",")
    word_lengths = input_words |> Enum.map(&byte_size/1) |> Enum.uniq()

    if Enum.count(word_lengths) > 1 do
      raise "not all words are the same length"
    end

    word_list =
      WordList.get(Application.get_env(:wordle_solver, :word_list_url), List.first(word_lengths))

    {word_list, input_words}
  end

  defp calculate_analytics([], _analytics_file, _word_list, _threads), do: :ok

  defp calculate_analytics(input_words, analytics_file, word_list, threads) do
    IO.puts("Running analytics on #{inspect(input_words)}")

    letter_distribution = LetterDistribution.build(word_list)

    sorted_list =
      word_list
      |> Enum.sort_by(fn word -> LetterDistribution.rank_word(letter_distribution, word) end)
      |> Enum.reverse()

    batch_size = max(div(Enum.count(sorted_list), threads), 1)

    input_words
    |> Enum.chunk_every(batch_size)
    |> Stream.with_index(1)
    |> Enum.map(fn {word_batch, i} ->
      Task.async(fn ->
        Enum.each(word_batch, fn start_word ->
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
    end)
    |> List.flatten()
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
    |> String.split("\n")
    |> Enum.reject(fn row -> String.trim(row) == "" end)
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
