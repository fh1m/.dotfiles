# Agent-authored native validation; not owner achievement.
import heapq
import math

def shortest_paths(vertices, edges, source):
    if any(w < 0 for _, _, w in edges):
        raise ValueError("Dijkstra requires nonnegative weights")
    adjacency = {v: [] for v in vertices}
    for u, v, w in edges:
        adjacency[u].append((v, w))
    distance = dict.fromkeys(vertices, math.inf)
    distance[source] = 0
    queue = [(0, source)]
    while queue:
        cost, u = heapq.heappop(queue)
        if cost != distance[u]:
            continue
        for v, w in adjacency[u]:
            candidate = cost + w
            if candidate < distance[v]:
                distance[v] = candidate
                heapq.heappush(queue, (candidate, v))
    return distance
