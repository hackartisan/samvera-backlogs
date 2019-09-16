# samvera-backlogs

## Presentation proposal

I will use Natural Language Processing and Machine Learning techniques to
analyze issue backlogs in applications from institutions throughout the
community. I will apply a variety of techniques in an attempt to answer
questions like:

* What kinds of open issues do we have in general as a community?
  * Can I extract an interesting set of widely-desired features or widely-held use
cases?
  * Can I identify connections that might lead to collaboration across institutions?
* What solutions already exist that might advance open issues?
  * Can I link open issues in one backlog to merged PRs in another repository?
* What have people been working on recently?
  * Can we characterize the full set of issues that have been closed over the past
year?
* What patterns of development do repositories follow?
  * Can we describe the life cycle of repository development by aligning issues
based on their creation / completion dates relative to the initial commit?

These may or may not be the exact questions my talk will address, depending on
the direction the project naturally takes. I will focus on applications in use
or under development at institutions, as opposed to community-maintained engines
and core gems. This talk will describe my process, results, and evaluate the
success of the endeavor.

## Project plan

* Create the data set
  * Collect repositories
    * Identify repositories to get dependencies from
      * hyrax
      * sufia
      * valkyrie
      * hydra-head
      * hydra
    * Pull them via github API?
    * At some point do we have too many? to effective analyze results?
  * Pull the issues and PRs using the github api
  * Tagging? Maybe do this later when relevant for a specific question
* Ask for money from Esmé, Jon in case we need it
* Choose a first question
  * See what we can do using google's tools
  * Analyze results and iterate
