defmodule FilterTest do
  use ExUnit.Case

  describe "apply" do
    test "narrows list by exclusion" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "a"},
          {:no_match, 1, "b"},
          {:no_match, 2, "c"},
          {:no_match, 3, "d"},
          {:no_match, 4, "e"}
        ]
      }

      list = ["aaaaa", "bbbbb", "ccccc", "ddddd", "eeeee", "fffff"]

      assert Filter.apply(filter, list) == ["fffff"]
    end

    test "narrows list by exact match" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "a"},
          {:exact_match, 1, "b"},
          {:exact_match, 2, "c"},
          {:exact_match, 3, "d"},
          {:exact_match, 4, "e"}
        ]
      }

      list = ["aaaaa", "bbbbb", "ccccc", "ddddd", "eeeee", "fffff", "abcde"]

      assert Filter.apply(filter, list) == ["abcde"]
    end

    test "narrows list by contains match" do
      filter = %Filter{
        positions: [
          {:contains_match, 0, "a"},
          {:contains_match, 1, "b"},
          {:contains_match, 2, "c"},
          {:contains_match, 3, "d"},
          {:contains_match, 4, "e"}
        ]
      }

      list = ["aaaaa", "bbbbb", "ccccc", "ddddd", "eeeee", "fffff", "bcdea"]

      assert Filter.apply(filter, list) == ["bcdea"]
    end

    test "narrows list with double letters" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "a"},
          {:contains_match, 1, "a"},
          {:no_match, 2, "b"},
          {:no_match, 3, "a"},
          {:no_match, 4, "a"}
        ]
      }

      list = ["acccc", "aaccc", "acacc"]

      assert Filter.apply(filter, list) == ["acacc"]
    end

    test "debug test" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "b"},
          {:exact_match, 1, "o"},
          {:no_match, 2, "s"},
          {:exact_match, 3, "k"},
          {:exact_match, 4, "s"}
        ]
      }

      list = ["bosks", "books", "zooks", "jooks", "kooks"]

      assert Filter.apply(filter, list) == ["books"]
    end
  end

  describe "build" do
    test "build filter correctly for exact match" do
      input = "aaaaa"
      target = "aaaaa"

      assert Filter.build(input, target) == %Filter{
               positions: [
                 {:exact_match, 0, "a"},
                 {:exact_match, 1, "a"},
                 {:exact_match, 2, "a"},
                 {:exact_match, 3, "a"},
                 {:exact_match, 4, "a"}
               ]
             }
    end

    test "build filter correctly for no match" do
      input = "aaaaa"
      target = "bbbbb"

      assert Filter.build(input, target) == %Filter{
               positions: [
                 {:no_match, 0, "a"},
                 {:no_match, 1, "a"},
                 {:no_match, 2, "a"},
                 {:no_match, 3, "a"},
                 {:no_match, 4, "a"}
               ]
             }
    end

    test "build filter correctly for contains match" do
      input = "baaaa"
      target = "cbccc"

      assert Filter.build(input, target) == %Filter{
               positions: [
                 {:contains_match, 0, "b"},
                 {:no_match, 1, "a"},
                 {:no_match, 2, "a"},
                 {:no_match, 3, "a"},
                 {:no_match, 4, "a"}
               ]
             }
    end

    test "build filter correctly for exact and contains match for the same letter" do
      input = "aabbb"
      target = "accca"

      assert Filter.build(input, target) == %Filter{
               positions: [
                 {:exact_match, 0, "a"},
                 {:contains_match, 1, "a"},
                 {:no_match, 2, "b"},
                 {:no_match, 3, "b"},
                 {:no_match, 4, "b"}
               ]
             }
    end

    test "build filter correctly for exact multiple exact matches with the same letter" do
      input = "sices"
      target = "sises"

      assert Filter.build(input, target) == %Filter{
        positions: [
          {:exact_match, 0, "s"},
          {:exact_match, 1, "i"},
          {:no_match, 2, "c"},
          {:exact_match, 3, "e"},
          {:exact_match, 4, "s"}
        ]
      }
    end

    test "build filter correctly for contains matches for same letter" do
      input = "hippy"
      target = "piggy"

      assert Filter.build(input, target) == %Filter{
        positions: [
          {:no_match, 0, "h"},
          {:exact_match, 1, "i"},
          {:contains_match, 2, "p"},
          {:no_match, 3, "p"},
          {:exact_match, 4, "y"}
        ]
      }
    end

    test "prioritize exact match over contains match" do
      input = "aaaaa"
      target = "bbbba"

      assert Filter.build(input, target) == %Filter{
               positions: [
                 {:no_match, 0, "a"},
                 {:no_match, 1, "a"},
                 {:no_match, 2, "a"},
                 {:no_match, 3, "a"},
                 {:exact_match, 4, "a"}
               ]
             }
    end
  end

  describe "excluded_characters" do
    test "correctly excludes characters" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "r"},
          {:no_match, 1, "o"},
          {:no_match, 2, "g"},
          {:no_match, 3, "u"},
          {:no_match, 4, "e"}
        ]
      }

      assert Filter.excluded_characters(filter) == MapSet.new(["r", "o", "g", "u", "e"])
    end

    test "correctly excludes characters for duplicates" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "a"},
          {:no_match, 1, "a"},
          {:no_match, 2, "a"},
          {:no_match, 3, "a"},
          {:no_match, 4, "a"}
        ]
      }

      assert Filter.excluded_characters(filter) == MapSet.new(["a"])
    end

    test "does not exclude characters that are a match before" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "a"},
          {:no_match, 1, "a"},
          {:no_match, 2, "a"},
          {:no_match, 3, "a"},
          {:no_match, 4, "a"}
        ]
      }

      assert Filter.excluded_characters(filter) == MapSet.new([])
    end
  end

  describe "regexes" do
    test "correctly calculates regexes for no matches" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "r"},
          {:no_match, 1, "o"},
          {:no_match, 2, "g"},
          {:no_match, 3, "u"},
          {:no_match, 4, "e"}
        ]
      }

      assert Filter.regexes(filter) == [
               ~r{^[^r]....$},
               ~r{^.[^o]...$},
               ~r{^..[^g]..$},
               ~r{^...[^u].$},
               ~r{^....[^e]$}
             ]
    end

    test "correctly calculates regexes for exact matches" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "a"},
          {:exact_match, 1, "a"},
          {:exact_match, 2, "a"},
          {:exact_match, 3, "a"},
          {:exact_match, 4, "a"}
        ]
      }

      assert Filter.regexes(filter) == [
               ~r{^a....$},
               ~r{^.a...$},
               ~r{^..a..$},
               ~r{^...a.$},
               ~r{^....a$}
             ]
    end

    test "correctly calculates regexes for contains matches" do
      filter = %Filter{
        positions: [
          {:contains_match, 0, "a"},
          {:contains_match, 1, "a"},
          {:contains_match, 2, "a"},
          {:contains_match, 3, "a"},
          {:contains_match, 4, "a"}
        ]
      }

      assert Filter.regexes(filter) == [
               ~r{^[^a]....$},
               ~r{^.[^a]...$},
               ~r{^..[^a]..$},
               ~r{^...[^a].$},
               ~r{^....[^a]$}
             ]
    end

    test "correctly calculates regexes for mixed matches" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "b"},
          {:no_match, 1, "o"},
          {:exact_match, 2, "o"},
          {:contains_match, 3, "k"},
          {:contains_match, 4, "s"}
        ]
      }

      assert Filter.regexes(filter) == [
               ~r{^[^b]....$},
               ~r{^.[^o]...$},
               ~r{^..o..$},
               ~r{^...[^k].$},
               ~r{^....[^s]$}
             ]
    end
  end

  describe "tally" do
    test "correctly calculates tally for no matches" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "r"},
          {:no_match, 1, "o"},
          {:no_match, 2, "g"},
          {:no_match, 3, "u"},
          {:no_match, 4, "e"}
        ]
      }

      assert Filter.tally(filter) == %{}
    end

    test "correctly calculates tally for exact matches" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "a"},
          {:exact_match, 1, "a"},
          {:exact_match, 2, "a"},
          {:exact_match, 3, "a"},
          {:exact_match, 4, "a"}
        ]
      }

      assert Filter.tally(filter) == %{"a" => 5}
    end

    test "correctly calculates tally for contains matches" do
      filter = %Filter{
        positions: [
          {:contains_match, 0, "a"},
          {:contains_match, 1, "a"},
          {:contains_match, 2, "a"},
          {:contains_match, 3, "a"},
          {:contains_match, 4, "a"}
        ]
      }

      assert Filter.tally(filter) == %{"a" => 5}
    end

    test "correctly calculates tally for mixed matches" do
      filter = %Filter{
        positions: [
          {:exact_match, 0, "a"},
          {:exact_match, 1, "a"},
          {:contains_match, 2, "a"},
          {:contains_match, 3, "a"},
          {:contains_match, 4, "a"}
        ]
      }

      assert Filter.tally(filter) == %{"a" => 5}
    end

    test "correctly calculates tally for mixed matches and different letters" do
      filter = %Filter{
        positions: [
          {:no_match, 0, "r"},
          {:exact_match, 1, "o"},
          {:contains_match, 2, "b"},
          {:contains_match, 3, "o"},
          {:no_match, 4, "t"}
        ]
      }

      assert Filter.tally(filter) == %{"o" => 2, "b" => 1}
    end
  end
end
