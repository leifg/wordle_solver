defmodule WordList do
  @word_list_local "tmp/word_list.txt"

  def get(url, length) do
    if File.exists?(@word_list_local) do
      IO.puts("Word list already downloaded")
    else
      IO.puts("Downloading word list")
      System.cmd("wget", [url, "-O", "#{@word_list_local}.tmp"])
      content = File.read!("#{@word_list_local}.tmp")
      {:ok, file} = File.open(@word_list_local, [:write])

      content
      |> String.split("\n")
      |> Enum.each(fn word -> IO.binwrite(file, "#{String.downcase(word)}\n") end)

      File.close(file)
      File.rm("#{@word_list_local}.tmp")
    end

    init_word_list(@word_list_local, length)
  end

  defp init_word_list(filename, length) do
    filename
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(fn word -> String.length(word) == length end)
  end
end
