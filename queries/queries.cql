// See who has the biggest rivalries
MATCH (a)-[r:LOST_TO]->(b) 
RETURN a.fname, type(r), b.fname, count(r) 
ORDER BY count(r) DESC

// Create graph projection for the homogeneous graph (Person)-[LOST_TO]->(Person)
// This is a necessary prerequisite for running PageRank
// The projected graph is called rivalry
CALL gds.graph.project(
  'rivalry',
  'Person',
  'LOST_TO'
)

// Estimate the amount of memory needed to run PageRank on the projected graph rivalry
CALL gds.pageRank.write.estimate('rivalry', {
  writeProperty: 'pageRank',
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

// Run PageRank - this does not write the result to the projected graph or the database itself
CALL gds.pageRank.stream('rivalry')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).fname AS fname, score
ORDER BY score DESC, fname ASC

// Run PageRank and write the results to the database
CALL gds.pageRank.write('rivalry', {
  maxIterations: 20,
  dampingFactor: 0.85,
  writeProperty: 'pagerank'
})
YIELD nodePropertiesWritten, ranIterations

// Sort by largest pagerank
MATCH (p:Person) 
RETURN p.fname, p.pagerank 
ORDER BY p.pagerank DESC

// Assign a weight of 0.7 to tiebreakers from seasons 1 and 2
MATCH (:Person)-[l:LOST_TO]->(:Person)
WHERE l.dt <= '3/22/2023'
SET l.weight = 0.7

// Assign weight of 1.0 to tiebreakers from seasons 3 and 4
MATCH (:Person)-[l:LOST_TO]->(:Person)
WHERE l.dt > '3/22/2023'
SET l.weight = 1

// Create projected graph with weights
CALL gds.graph.project(
  'rivalry_weighted',
  'Person',
  'LOST_TO',
  {
    relationshipProperties: 'weight'
  }
)

// Run PageRank on the weighted graph - no write
CALL gds.pageRank.stream('rivalry_weighted', {
  maxIterations: 20,
  dampingFactor: 0.85,
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).fname AS fname, apoc.number.format(score) AS score
ORDER BY score DESC, fname ASC

// Write PageRank weighted property to graph
CALL gds.pageRank.write('rivalry_weighted', {
  maxIterations: 20,
  dampingFactor: 0.85,
  writeProperty: 'pagerank_weighted',
  relationshipWeightProperty: 'weight'
})
YIELD nodePropertiesWritten, ranIterations

// Count of number of people with the winning score by day
MATCH (:Person)-[d:HAS]->(r:Result)
WITH distinct d.dt AS dt, min(r.result) AS win_score
MATCH (p:Person)-[d:HAS {dt:dt}]->(r:Result {result:win_score})
RETURN distinct d.dt AS date, count(p) AS num_with_win_score, r.result AS win_score
ORDER BY date

// Number of "mic dropper" days (i.e. uncontested victories)
MATCH (:Person)-[d:HAS]->(r:Result)
WITH distinct d.dt AS dt, min(r.result) AS win_score
MATCH (p:Person)-[d:HAS {dt:dt}]->(r:Result {result:win_score})
WITH distinct d.dt AS date, count(p) AS num_with_win_score, r.result AS win_score
WHERE num_with_win_score = 1
RETURN count(date)

// Number of "mic drops" by person
MATCH (:Person)-[d:HAS]->(r:Result)
WITH distinct d.dt AS dt, min(r.result) AS win_score
MATCH (p:Person)-[d:HAS {dt:dt}]->(r:Result {result:win_score})
WITH distinct d.dt AS date, count(p) AS num_with_win_score, win_score
WHERE num_with_win_score = 1
MATCH (p:Person)-[d:HAS {dt:date}]->(r:Result {result:win_score})
RETURN p.fname, count(d)
ORDER BY count(d) DESC

// Total wins by person
MATCH (p:Person)-[h:HAS {win:'1'}]->(:Result)
RETURN p.fname, count(h) AS wins
ORDER BY wins DESC

// Pageranked person results (weighted)
MATCH (n:Person) 
RETURN n.fname, n.pagerank_weighted 
ORDER BY n.pagerank_weighted DESC

// Print the named graphs in the database
CALL gds.graph.list()
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount
ORDER BY graphName ASC

// Win percentage by person in tiebreakers
MATCH (p1:Person)-[l:LOST_TO]->(:Person)
WITH p1.fname AS fname, count(l.dt) AS num_losses
MATCH (:Person)-[w:LOST_TO]->(p1:Person {fname:fname})
WITH p1.fname AS fname, num_losses, count(distinct w.dt) AS num_wins
RETURN fname, num_losses, num_wins, num_losses + num_wins AS num_tiebreakers, apoc.number.format(toFloat(num_wins) / (num_wins + num_losses)) AS win_pct
ORDER BY win_pct DESC

// win percentages pairwise in tiebreakers
MATCH (p1:Person)-[l:LOST_TO]->(p2:Person)
WITH p1.fname AS fname1, p2.fname AS fname2, count(l.dt) AS num_losses
MATCH (p2:Person {fname:fname2})-[w:LOST_TO]->(p1:Person {fname:fname1})
WITH p1.fname AS fname1, p2.fname AS fname2, num_losses, count(distinct w.dt) AS num_wins
WITH fname1, fname2, num_losses, num_wins, num_losses + num_wins AS num_tiebreakers, apoc.number.format(toFloat(num_wins) / (num_wins + num_losses)) AS win_pct
WHERE win_pct >= '0.5' // result set is symmetric about 0.5
RETURN fname1, 'beat', fname2, num_wins, num_losses, num_tiebreakers, win_pct
ORDER BY win_pct DESC