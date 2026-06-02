// 5.1. Page rank algorithm
// Крок 1: Матеріалізація ребер фільм-фільм
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20 AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 5000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: Створення проєкції
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск алгоритму PageRank (Stream mode)
CALL gds.pageRank.stream('movieGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS MovieTitle, 
       gds.util.asNode(nodeId).year AS Year, 
       score AS PageRankScore
ORDER BY PageRankScore DESC
LIMIT 10;

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;


// 5.2 Louvain algorithm
// Крок 1: Матеріалізація ребер схожості користувачів
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 5000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: Створення проєкції
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск Louvain із записом результатів у граф (Write mode)
CALL gds.louvain.write('userSimilarity', {
  writeProperty: 'louvainCommunity',
  relationshipWeightProperty: 'weight'
})
YIELD communityCount, modularity, modularities;

// Крок 4а: Топ-10 найбільших спільнот за кількістю користувачів
MATCH (u:User)
WHERE u.louvainCommunity IS NOT NULL
RETURN u.louvainCommunity AS CommunityID, count(u) AS ClusterSize
ORDER BY ClusterSize DESC
LIMIT 10;

// Крок 4б: Профілювання спільнот (Топ-3 жанри для кожної з найбільших спільнот)
MATCH (u:User)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4 AND u.louvainCommunity IS NOT NULL
WITH u.louvainCommunity AS CommunityID, g.name AS GenreName, count(r) AS GenreCount
ORDER BY CommunityID, GenreCount DESC
WITH CommunityID, collect({genre: GenreName, count: GenreCount})[..3] AS TopGenres
RETURN CommunityID, TopGenres
ORDER BY size(TopGenres) DESC
LIMIT 10;

// Крок 5: Очищення пам'яті та зв'язків
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;


// 5.3. Dijkstra algorithm
// Відновлюємо ребра та проєкцію для пошуку шляхів
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 5000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Пошук найкоротшого шляху Дейкстри за вагою (спільними фільмами)
// (Замініть '1' та '10' на будь-які валідні userId з вашої бази)
MATCH (source:User {userId: '1'}), (target:User {userId: '10'})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target,
  relationshipWeightProperty: 'weight'
})
YIELD nodeIds, costs
RETURN [nodeId IN nodeIds | gds.util.asNode(nodeId).userId] AS PathOfUserIds,
       costs AS CumulativeWeights;

// Крок 4: Очищення пам'яті та зв'язків
CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;
