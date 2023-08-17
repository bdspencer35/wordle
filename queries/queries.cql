// Create LOST_TO relationship so that arrow points to the winner
MATCH (p1:Person)-[r1:HAS]->(rs:Result)
MATCH (p2:Person)-[r2:HAS]->(rs)
WHERE r1.dt = r2.dt
AND p1 <> p2
AND r1.tiebreak = '1'
CREATE (p2)-[:LOST_TO {dt:r1.dt}]->(p1)

// See who has the biggest rivalries
MATCH (a)-[r:LOST_TO]->(b) 
RETURN a.fname, type(r), b.fname, count(r) 
ORDER BY count(r) DESC

