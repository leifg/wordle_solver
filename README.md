# WordleSolver

This is a naive approach for a generic solver for the popular online game [Wordle](https://www.powerlanguage.co.uk/wordle/).

It is still under heavy development.

## Usage

Install dependencies via `mix deps.get`

### Configuration

By default the word list used is the [Scrabble Dictionary](https://raw.githubusercontent.com/jesstess/Scrabble/master/scrabble/sowpods.txt) list.

You can use any word list as long as it is delimited by new lines.

### Solving

To find out how many attempts it would have taken to solve a word run the `solve` mix task. Make sure to enter the words in lower case characters.

```shell
mix solve [target] [start_word]
```

Example:

```shell
mix solve tiger water
> Solved in 5 attempts
```

### Show Distribution

To analyze the word list and show the distribution of letters and which words are ranked highest for a fixed length, run the `show_distribution` task.

For 5 letter words use:

```shell
mix show_distribution 5
```


### Build Analytics

**WARNING: This tasks take a while to complete

To figure out how many attempts a specific start word yields for every other word run the `analyze` task.

Example

```shell
mix analyze water,tiger,crazy
```

This will create a `tmp/distribution.jsonl` file where every line shows the guesses needed for every other word. Additionally it will print out how many words need more than 6 guesses to find.
