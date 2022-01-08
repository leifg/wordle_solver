defmodule Filter do
  defstruct [:excluded_characters, :positions, :matching_regexes]

  def build(input, target) when byte_size(input) != byte_size(target) do
    raise "incompatible word length"
  end

  def build(input, target) do
    input_char_list = String.codepoints(input)
    target_char_list = String.codepoints(target)
    indexes = 0..(length(target_char_list) - 1)

    positions =
      input_char_list
      |> Enum.zip(target_char_list)
      |> Enum.zip(indexes)
      |> Enum.map(fn {{input_char, target_char}, position} ->
        cond do
          input_char == target_char -> {:exact_match, position, input_char}
          String.contains?(target, input_char) -> {:contains_match, position, input_char}
          true -> {:no_match, position, input_char}
        end
      end)

    excluded_characters =
      positions
      |> Enum.filter(fn match ->
        case match do
          {:no_match, _, _} -> true
          {_, _, _} -> false
        end
      end)
      |> Enum.map(fn {_op, _pos, char} -> char end)

    %__MODULE__{
      excluded_characters: excluded_characters,
      positions: positions,
      matching_regexes: positions_to_regex_list(positions)
    }
  end

  def apply(filter, list) do
    list
    |> Enum.reject(fn word ->
      Enum.any?(filter.excluded_characters, fn char ->
        String.contains?(word, char)
      end)
    end)
    |> Enum.filter(fn word ->
      Enum.all?(filter.matching_regexes, fn regex -> String.match?(word, regex) end)
    end)
  end

  defp positions_to_regex_list(positions) do
    length = Enum.count(positions)

    positions
    |> Enum.map(fn match ->
      case match do
        {:exact_match, pos, char} ->
          [build_matching_regex(char, length, pos)]

        {:contains_match, pos, char} ->
          [Regex.compile!(char), build_matching_regex("[^#{char}]", length, pos)]

        {_, _, _} ->
          []
      end
    end)
    |> List.flatten()
  end

  defp build_matching_regex(char, length, position) do
    "."
    |> List.duplicate(length)
    |> List.replace_at(position, char)
    |> Enum.join("")
    |> Kernel.then(&"^#{&1}$")
    |> Regex.compile!()
  end
end
