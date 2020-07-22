# Batting Averages Backend Exercise

Batting average is simple and a common way to measure batter’s performance.
Create an app that will ingest a raw CSV file with player statistics and
provide will provide player rankings based on their batting performance.

## Input

The application should take an input in form of a CSV file. The file will be
comma separated CSV with headers. The headers that interest you are: “playerID”,
“yearID”, “stint”, teamID”, “AB”, and “H”.

The application should also accept filter options:
- Year
- Team name
- Year and Team name

When filter are present, the output should include only players that match
the filter, sorted according to their batting average.


## Expected output

Batting Average is calculated as: BA = H/AB (Hits / At Bats).

If the player has more stints in the season, calculate batting average for the
whole season (across all stints), team names are comma separated in that case.
Format the batting average to 3 decimals.

Write a standalone command line app

The output should be like a following table:

```
+----------+--------+--------------+-----------------+
| playerID | yearId | Team name(s) | Batting Average |
+----------+--------+--------------+-----------------+
| ...                                                |
+----------------------------------------------------+
```


## CSV files

The input CSV file is in `data/Batting.csv`. This file includes "teamID", use the
file `data/Teams.csv` to map "teamID" to a team's real name.

---

# Exercice Implementation

## A. Installation

1- Use RVM or rbenv
2- clone this repository and `cd` into it, then `bundle install`

The dependencies are:

+ [Thor](http://whatisthor.com/) for the main command entry
+ [tty-spinner](https://github.com/piotrmurach/tty-spinner) for the UI when the CSV is loading. From the excelent [TTY toolkit](https://ttytoolkit.org/) suite.
+ [tty-table](https://github.com/piotrmurach/tty-table) to format the ranking results in ASCII tables
+ [Paint](https://github.com/janlelis/paint) to color the blue prompt

## B. Running the CLI app

This app uses Thor for the main command. Just execute `thor display:batting_averages_ranking` to launch it.

## C. UI

Once launched, you'll play with an interactive REPL which on first time loads and process the CSV data (100k+ lines).

The first result will be the all time top 30 batting average rankings

Just below it you have a blue prompt |> where you enter specific commands to play with the ranking table

## D. Commands

Type `h` or `help` (case insensitive) to display available commands. They are self-explanatory:

1. `all` or ENTER -> displays global ranking
2. `in {4_digits_year}` -> displays ranking for this year
3. `of {team_name}` -> displays ranking within this team from its inception
4. `of {team_name} in {4_digits_year}` -> combination of 2 and 3
5. `list years`
6. `list teams`
7. `n` or `next` -> go to next page
8. `p` or `previous` -> back to previous page
9. `q` or Ctrl+D -> exit

## E. Pagination

The results are paginated by batches of 30 lines from top ranked player per year.

Type `n` or `next` to descend the ranking table. Or `p` or `previous` to go back to upper ranks.

## F. Test

Quite simple, just run `rake` or `rake test` to launch the test

The test file skips the CSV parsing and jumps directly to use parsed data. A global test matrix is provided on top for better understandability.

## G. Internal architecture

The app is separated in 3 layers

1. The Thor command that launches the app
2. UI layer, implemented in `lib/batting_averages_ui.rb`. This layer handles the output presentation, the textual interactivity and the REPL loop
3- Engine layer, implemented in `lib/batting_averages_engine.rb`. This layer is responsible of the CSV parsing and ranking calculations

**Strategies**

+ Caching of the global ranking because this is heavy to process (100k+ lines and we cannot leverage indexes)
+ Ahead of time indexing by year and by team. This speeds up the parsing when filtering is asked by the user (no need of cache)
+ Usage of Set: offers a time complexity advantage when filtering is asked by the user (~ set intersection)
+ For readability in the UI, the tables are presented in pages of 30 by 30, which is reset to page 1 (top ranks) whenever the filtering criteria changes

