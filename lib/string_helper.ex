defmodule StringHelper do
  def replace_at(input, index, char) do
    input
    |> String.graphemes()
    |> Stream.with_index(0)
    |> Enum.map(fn {c, i} ->
      if i == index do
        char
      else
        c
      end
    end)
    |> Enum.join("")
  end
end
