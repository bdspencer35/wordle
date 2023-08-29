// Load script

CREATE DATABASE wordle
:use wordle;

// Person nodes
LOAD CSV WITH HEADERS FROM 'file:////Users/bspencer/Documents/GitHub/wordle/data/entity.csv' AS line
CREATE (:Person {fname:line.fname});

// Result nodes
LOAD CSV WITH HEADERS FROM 'file:///Users/bspencer/Documents/GitHub/wordle/data/result.csv' AS line
CREATE (:Result {result:toInteger(line.result)});

// (Person)-[HAS]->(Result)
LOAD CSV WITH HEADERS FROM 'file:///Users/bspencer/Documents/GitHub/wordle/data/results.csv' AS line
MATCH (p:Person {fname:line.fname})
MATCH (r:Result {result:toInteger(line.result)})
CREATE (p)-[:HAS {dt:date(line.date), win:toInteger(line.win)}]->(r);

// (Person)-[LOST_TO]->(Person) arrow points to the winner
MATCH (p1:Person)-[r1:HAS]->(rs:Result)
MATCH (p2:Person)-[r2:HAS]->(rs)
WHERE r1.dt = r2.dt
AND p1 <> p2
AND r1.win = 1
CREATE (p2)-[:LOST_TO {dt:date(r1.dt)}]->(p1);