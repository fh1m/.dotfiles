# Agent-authored discovery-finalization mistake, not owner work.
import math
def shortest_paths(vertices, edges, source):
    if any(w < 0 for _, _, w in edges): raise ValueError("nonnegative required")
    d = dict.fromkeys(vertices, math.inf); d[source] = 0; queue = [source]
    while queue:
        u = queue.pop(0)
        for a, b, w in edges:
            if a == u and d[b] == math.inf:
                d[b] = d[a] + w; queue.append(b)
    return d
