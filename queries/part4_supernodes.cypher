// Top 10 users with the bigest amount og grades
MATCH (u:User)-[r:RATED]->()
WITH u, count(r) AS degree
RETURN u.userId AS UserID, u.age AS Age, u.gender AS Gender, degree
ORDER BY degree DESC
LIMIT 10;

// The most popular films - receive grades more than others
MATCH (m:Movie)<-[r:RATED]-()
WITH m, count(r) AS degree
RETURN m.title AS MovieTitle, m.year AS Year, degree
ORDER BY degree DESC
LIMIT 10;

// The most popular genres
MATCH (g:Genre)<-[r:HAS_GENRE]-()
WITH g, count(r) AS degree
RETURN g.name AS GenreName, degree
ORDER BY degree DESC;
