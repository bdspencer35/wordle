// Load script

// Person nodes
LOAD CSV WITH HEADERS FROM 'file:///C:\Users\\bspencer\Documents\GitHub\wordle\data\entity.csv' AS line
CREATE (:Person {fname:line.fname})

// Result nodes
LOAD CSV WITH HEADERS FROM 'file:///C:\Users\\bspencer\Documents\GitHub\wordle\data\\result.csv' AS line
CREATE (:Result {result:line.result})

// (Person)-[HAS]->(Result)
LOAD CSV WITH HEADERS FROM 'file:///C:\Users\\bspencer\Documents\GitHub\wordle\data\\results.csv' AS line
MATCH (p:Person {fname:line.fname})
MATCH (r:Result {result:line.result})
CREATE (p)-[:HAS {dt:line.date, win:line.win, tiebreak:line.tiebreak}]->(r)

// Create LOST_TO relationship so that arrow points to the winner
MATCH (p1:Person)-[r1:HAS]->(rs:Result)
MATCH (p2:Person)-[r2:HAS]->(rs)
WHERE r1.dt = r2.dt
AND p1 <> p2
AND r1.tiebreak = '1'
CREATE (p2)-[:LOST_TO {dt:r1.dt}]->(p1)