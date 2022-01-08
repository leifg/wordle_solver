defmodule Filter do
  defstruct [:positions]

  def build(input, target) when byte_size(input) != byte_size(target) do
    raise "incompatible word length"
  end

  def build(input, target) do
    input_chars = String.graphemes(input)

    {input_without_exact_matches, output_without_exact_matches, exact_matches_positions} =
      input_chars
      |> Stream.with_index(0)
      |> Enum.reduce({input, target, %{}}, fn {char, index},
                                              {remaining_input_word, remaining_output_word,
                                               positions} ->
        {remaining_input_word, remaining_output_word, match} =
          if String.at(target, index) == char do
            {
              StringHelper.replace_at(remaining_input_word, index, "."),
              StringHelper.replace_at(remaining_output_word, index, "."),
              {:exact_match, index, char}
            }
          else
            {
              remaining_input_word,
              remaining_output_word,
              {:no_match, index, char}
            }
          end

        {
          remaining_input_word,
          remaining_output_word,
          Map.merge(positions, %{index => match})
        }
      end)

    {_, contains_matches_positions} =
      input_without_exact_matches
      |> String.graphemes()
      |> Stream.with_index(0)
      |> Enum.reduce({output_without_exact_matches, %{}}, fn {char, index},
                                                             {remaining_word, positions} ->
        if char != "." && String.contains?(remaining_word, char) do
          {
            String.replace(remaining_word, char, "."),
            Map.merge(positions, %{index => {:contains_match, index, char}})
          }
        else
          {remaining_word, positions}
        end
      end)

    priority = fn match_1 = {match_type_1, _, _}, match_2 ->
      case match_type_1 do
        :exact_match -> match_1
        _ -> match_2
      end
    end

    merged_positions =
      exact_matches_positions
      |> Map.merge(contains_matches_positions, fn _k, v1, v2 -> priority.(v1, v2) end)
      |> Map.values()
      |> Enum.sort_by(fn {_type, index, _char} -> index end)

    %__MODULE__{
      positions: merged_positions
    }
  end

  def apply(filter, list) do
    list
    |> Enum.reject(fn word ->
      Enum.any?(
        Filter.excluded_characters(filter),
        fn char ->
          String.contains?(word, char)
        end
      )
    end)
    |> Enum.filter(fn word ->
      Enum.all?(Filter.tally(filter), fn {letter, count} ->
        word |> String.graphemes() |> Enum.count(&(&1 == letter)) >= count
      end)
    end)
    |> Enum.filter(fn word ->
      Enum.all?(Filter.regexes(filter), fn regex -> String.match?(word, regex) end)
    end)
  end

  def excluded_characters(%{positions: positions}) do
    {no_match, match} =
      Enum.split_with(positions, fn match ->
        case match do
          {:no_match, _, _} -> true
          {_, _, _} -> false
        end
      end)

    no_match_chars =
      no_match |> Enum.map(fn {_op, _pos, char} -> char end) |> Enum.into(MapSet.new())

    match_chars = match |> Enum.map(fn {_op, _pos, char} -> char end) |> Enum.into(MapSet.new())

    MapSet.difference(no_match_chars, match_chars)
  end

  def regexes(%{positions: positions}) do
    length = Enum.count(positions)

    positions
    |> Enum.map(fn match ->
      case match do
        {:exact_match, pos, char} ->
          build_matching_regex(char, length, pos)

        {_, pos, char} ->
          build_matching_regex("[^#{char}]", length, pos)
      end
    end)
    |> List.flatten()
  end

  def tally(%{positions: positions}) do
    positions
    |> Enum.filter(fn match ->
      case match do
        {:no_match, _, _} -> false
        {_, _, _} -> true
      end
    end)
    |> Enum.reduce(%{}, fn {_op, _pos, char}, acc ->
      Map.merge(acc, %{char => 1}, fn _k, v1, v2 -> v1 + v2 end)
    end)
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
