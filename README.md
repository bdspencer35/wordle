# wordle

Storing Wordle group results as a graph

## graph

The graph representation of the Wordle results is densely connected. With just 8 `Person` nodes (number of players in group) and 6 `Result` nodes (number of possible Wordle answers) we end up with tens or hundreds of relationships between `Person` nodes and `Result` nodes. The graph can be thought about as two different graphs unioned together: (1) the daily result scores that each person submits and (2) the rivalry graph where a tiebreaker was needed to determine the winner of the day's Wordle.

### daily results graph

![image](results_graph_aug.png)
The above graph is just the results from August 2023. Visually with a smaller graph you can see where the majority of each person's guesses are going.
Edges contain the date each guess was made from a `Person` node to a `Result` node. Example: `(:Person {fname:'Brian'})-[:HAS {dt:'8/28/23'}]->(:Result {result:3})`. So for each day we end up with 1 edge for each `Person` pointing to 1 `Result` node. Below is an example that represents the group's scores capture on just one day.

![image](example_day_results.png)

If all 7 people play today, 7 edges are added. When all days are taken together it creates a very densely connected structure that we are not as much interested in visualizing but querying when the winning number of guesses was shared between two or more people. In this case we can build the rivalry graph which can give us more interesting details about which people compete in tiebreakers the most often. Who wins the most tiebreakers? This new `(Person)-->(Person)` type graph is homogeneous and also allows us to run graph centrality algorithms on it as well.

### rivalry graph

![image](rivalry_graph.png)

When two or more people share the lowest guess for the day, a tiebreaker is needed to determine the winner. In addition to containing the date on each edge, if a person won on the day there is a `win` flag that will be set to `1`. If a person did not win, the `win` flag is not present on the edge. Thus we can create a `LOST_TO` relationship between the person(s) who lost the tiebreaker to the winning person. The reason we create the relationship in this direction is for the graph algorithms that treat incoming edges as more influential.

Inside the `data` folder are the results of creating the graph based on the daily results, writing cypher queries to create the rivalry graph, and writing additional queries against this tiebreaker data.

## graph analytics

coming soon
