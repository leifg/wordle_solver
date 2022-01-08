defmodule WordleSolver do
  @word_list_url "https://raw.githubusercontent.com/jesstess/Scrabble/master/scrabble/sowpods.txt"
  @word_list_local "tmp/word_list.txt"

  def solve(target, seed) when byte_size(target) != byte_size(seed) do
    raise "Target and start words need to have the same length"
  end

  def solve(target, seed) do
    IO.puts("Solving for #{target} starting with #{seed}")
    download_word_list(@word_list_url)
    word_list = init_word_list(@word_list_local, String.length(target))

    validate_in_list(word_list, target, "target")
    validate_in_list(word_list, seed, "seed")

    iterate(word_list, seed, target, 1)
  end

  defp download_word_list(url) do
    if File.exists?(@word_list_local) do
      IO.puts("Word list already downloaded")
      :ok
    else
      IO.puts("Downloading word list")
      System.cmd("wget", [url, "-O", "#{@word_list_local}.tmp"])
      content = File.read!("#{@word_list_local}.tmp")
      {:ok, file} = File.open(@word_list_local, [:write])

      content
      |> String.split("\n")
      |> Enum.shuffle()
      |> Enum.each(fn word -> IO.binwrite(file, "#{String.downcase(word)}\n") end)

      File.open(@word_list_local)
      File.rm("#{@word_list_local}.tmp")
      :ok
    end
  end

  defp init_word_list(filename, length) do
    filename
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(fn word -> String.length(word) == length end)
  end

  defp validate_in_list(word_list, word, name) do
    unless Enum.member?(word_list, word) do
      raise "#{name} word '#{word}' not in list"
    end
  end

  defp iterate([], _input, _target, attempt) do
    IO.puts("Nothing found after #{attempt} attempts")
  end

  defp iterate(_word_list, target, target, attempt) do
    IO.puts("Target word #{target} found after #{attempt} attempts")
  end

  defp iterate(word_list, input, target, attempt) do
    filtered_list =
      input
      |> Filter.build(target)
      |> Filter.apply(word_list)
      |> IO.inspect(label: "list after attempt #{attempt}")

    next_word = next_word(filtered_list)

    iterate(filtered_list, next_word, target, attempt + 1)
  end

  defp next_word(list) do
    List.first(list)
  end
end
