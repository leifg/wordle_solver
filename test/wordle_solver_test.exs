defmodule WordleSolverTest do
  use ExUnit.Case
  doctest WordleSolver

  test "greets the world" do
    assert WordleSolver.hello() == :world
  end
end
