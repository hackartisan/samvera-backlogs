# Methods

## Selection / inclusion of code repositories

Repositories were included in this analysis if they met the following criteria:

 * Code is hosted on github
 * Code powers an end-user (staff or public) application at a specific
   institution or consortium
 * Code is not in a samvera github organization, i.e. is not already code that
   the community is manintaining collectively
 * Github repository contains 1 or more issues
 * Has a commit in the past 6 months

Consequences of these criteria:

 * Sometimes we weren't able to analyze highly relevant codebases, for example
   Project Surfliner is a valkyrie project currently in development but their
   issues are not on github. Because of the smaller number of valkyrie projects
   this represents a significant lost opportunity

Observations during this process:

 * Sometimes it felt a little sad, wading through a graveyard of unfinished
   projects; ideas never fully realized
 * There are a number of hyrax implementors that are more or less satisfied
   with the stock application or don’t have the developer capacity for continuous
   customization. And a few that are under active development.


## Techniques and Data sets per question

We've decided not to explore the last question in the proposal. It doesn't seem
as useful as the others and determining methods seems less straightforward. For
the other questions, we'll track thoughts on techniques and data set specifics
here.

In general, we'll primarily look to use clustering or topic modeling.

* What kinds of open issues do we have in general as a community? Can we extract an interesting set of widely-desired features or widely-held use
cases?
  * Analyze all open issues
* What solutions already exist that might advance open issues? Can I link open issues in one backlog to merged PRs in another repository?
  * Analyze open issues together with merged PRs
* What have people been working on recently? Can we characterize the full set of issues that have been closed over the past
    * Analyze closed issues -- use just the titles
year?


## Filename conventions

Since we'll have several different data sets for the various experiments we want
to run, we'll create different directories for different batches of downloads.
for example, `pull_requests`, `open_issues`, `closed_issues`, `recent_issues`,
`issue_titles`. We'll try naming the files themselves after the repository and
issue/pr number, e.g. `figgy_issue_2.txt`.


## File format

Simple rows of key: value entries.
