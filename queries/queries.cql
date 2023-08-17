// See who has the biggest rivalries
MATCH (a)-[r:LOST_TO]->(b) 
RETURN a.fname, type(r), b.fname, count(r) 
ORDER BY count(r) DESC

