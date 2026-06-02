// 1. Thriller movies with avarage rating more than 4.0
MATCH (g:Genre {name: 'Thriller'})<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-()
WITH m, avg(r.rating) AS avgRating
WHERE avgRating > 4.0
RETURN m.title AS MovieTitle, round(avgRating, 2) AS AverageRating
ORDER BY avgRating DESC;

// 2. Users that rated more than 50 movies with 5
MATCH (u:User)-[r:RATED]->(:Movie)
WHERE r.rating = 5
WITH u, count(r) AS countFiveRatings
WHERE countFiveRatings > 50
RETURN u.userId AS UserID, u.gender AS Gender, u.age AS Age, countFiveRatings
ORDER BY countFiveRatings DESC;

// 3. Movies that user1 and user2 rated with grade more than 4
MATCH (u1:User {userId: '1'})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: '2'})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title AS CommonMovie, r1.rating AS User1Rating, r2.rating AS User2Rating;

// 4. Genres with the high grades.
MATCH (g:Genre)<-[:HAS_GENRE]-(:Movie)<-[r:RATED]-()
WITH g, avg(r.rating) AS avgRating, count(r) AS totalRatings
WHERE totalRatings > 10000
RETURN g.name AS Genre, round(avgRating, 2) AS AvgRating, totalRatings
ORDER BY AvgRating DESC;

// 5. Recommendation system
MATCH (target:User {userId: '1'})-[r1:RATED]->(m1:Movie)<-[r2:RATED]-(peer:User)
WHERE abs(r1.rating - r2.rating) <= 1
WITH target, peer, count(m1) AS sharedMovies
WHERE sharedMovies >= 5
MATCH (peer)-[r3:RATED]->(recMovie:Movie)
WHERE r3.rating >= 4
  AND NOT (target)-[:RATED]->(recMovie)
RETURN recMovie.title AS RecommendedMovie, round(avg(r3.rating), 2) AS PeerAvgRating, count(peer) AS RecommendedByCount
ORDER BY RecommendedByCount DESC, PeerAvgRating DESC
LIMIT 10;

// 6. Shortest link between two users through the common films
MATCH p = shortestPath((u1:User {userId: '1'})-[:RATED*..10]-(u2:User {userId: '10'}))
RETURN p;
