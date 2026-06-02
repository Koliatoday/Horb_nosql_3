// Constraints will automatically creates indexes for the corresponding node fields.
CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.userId IS UNIQUE;

CREATE CONSTRAINT movie_id_unique IF NOT EXISTS
FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;

CREATE CONSTRAINT genre_name_unique IF NOT EXISTS
FOR (g:Genre) REQUIRE g.name IS UNIQUE;

// Load users
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: row.userId})
ON CREATE SET 
  u.gender = row.gender,
  u.age = toInteger(row.age),
  u.occupation = toInteger(row.occupation);

// Load movies and genres
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: row.movieId})
ON CREATE SET 
  m.title = substring(row.title, 0, size(row.title) - 7),
  m.year = toInteger(substring(row.title, size(row.title) - 5, 4))
WITH row, m
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

// Edges loading by batches
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: row.userId})
   MATCH (m:Movie {movieId: row.movieId})
   MERGE (u)-[r:RATED]->(m)
   ON CREATE SET 
     r.rating = toInteger(row.rating),
     r.timestamp = toInteger(row.timestamp)",
  {batchSize: 10000, parallel: false}
);

// Check for loading results
MATCH (u:User)  RETURN count(u) AS users;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH ()-[r:RATED]->() RETURN count(r) AS ratings;
