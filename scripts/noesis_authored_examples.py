# Agent-authored disposable test implementations, never installed as starters.

CONVOLUTION = '''"""Starter supplied by Noesis. Reconstruct/replace it; its authorship is not yours.
Centered odd kernel; same-length centers, explicit padding and optional subsampling.
"""
def convolve(signal, kernel, boundary="zero", stride=1, convention="convolution"):
    weights = kernel[::-1] if convention == "convolution" else kernel
    radius = len(kernel) // 2
    output = []
    for center in range(0, len(signal), stride):
        total = 0
        for j, weight in enumerate(weights):
            i = center + j - radius
            sample = signal[i] if 0 <= i < len(signal) else (
                0 if boundary == "zero" else signal[max(0, min(len(signal)-1, i))])
            total += sample * weight
        output.append(total)
    return output
'''

DIJKSTRA = '''# Agent-authored native validation; not owner achievement.
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
'''
