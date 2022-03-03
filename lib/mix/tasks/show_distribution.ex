defmodule Mix.Tasks.ShowDistribution do
  use Mix.Task

  @num_of_top_words 100

  def run([length_string]) do
    length = String.to_integer(length_string)

    IO.puts("letter distribution for #{length} letter words")

    word_list = WordList.get(Application.get_env(:wordle_solver, :word_list_url), length)
    letter_distribution = LetterDistribution.build(word_list)

    letter_distribution
    |> Enum.sort_by(fn {_k, v} -> -v end)
    |> IO.inspect(label: "letter distribution")

    word_list
    |> Enum.map(fn word -> LetterDistribution.rank_word(letter_distribution, word) end)
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.take(@num_of_top_words)
    |> IO.inspect(label: "highest ranking words", limit: :infinity)
  end
end


### OUTPUT

# === bemix,clunk,grypt,vozhd,waqfs
# Average: 1.2482769674627343
# Min:1
# Max: 8
# ======
# === blunk,cimex,grypt,vozhd,waqfs
# Average: 1.2186247796121172
# Min: 1
# Max: 8
# ======
# === brung,cylix,kempt,vozhd,waqfs
# Average: 1.231447347331303
# Min: 1
# Max: 8
# ======
# === brung,xylic,kempt,vozhd,waqfs
# Average: 1.2434685045680398
# Min: 1
# Max: 8
# ======
# === fjord,gucks,nymph,vibex,waltz
# Average: 1.1573970187530054
# Min: 1
# Max: 6
# ======
# === chunk,fjord,gymps,vibex,waltz
# Average: 1.155794197788107
# Min: 1
# Max: 6
# ======
# === glent,jumby,prick,vozhd,waqfs
# Average: 1.2439493508575092
# Min: 1
# Max: 8
# ======
# === clipt,jumby,kreng,vozhd,waqfs
# Average: 1.2502003526206122
# Min: 1
# Max: 8
# ======
# === jumby,pling,treck,vozhd,waqfs
# Average: 1.2295239621734253
# Min: 1
# Max: 6
# ======
# === bling,jumpy,treck,vozhd,waqfs
# Average: 1.2301650905593846
# Min: 1
# Max: 6
# ======
# === brick,glent,jumpy,vozhd,waqfs
# Average: 1.2471549927873056
# Min: 1
# Max: 8
# ======
