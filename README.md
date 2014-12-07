# Active Record Lite!

One of the solo projects in App Acaemy was to build our own version of Active Record.

We created some methods to be able to search in the database with simple queries.
Eventually we also created our own `belongs_to` and `has_many` methods.

I finished the project and went through the bonuses of `has_one_through` and `has_many_through`. Check the code in 
[here](https://github.com/lmuntaner/own_activerecord/blob/master/lib/04_associatable2.rb).

There are 3 different ways to do it: single query, using our own where methods or using `belongs_to` and `has_many`. The teacher assisstant told me that the best performance was the single query even though is the longest and the hardest to read. However, it makes sense since you are only querying the database once. I kept the rest of the code as a reminder.
