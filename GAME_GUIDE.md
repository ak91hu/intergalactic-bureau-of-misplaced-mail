# Game Guide
## The Intergalactic Bureau of Misplaced Mail

*"A package of unknown origin is somewhere in our facility.
We will use the power of algorithms to locate it —
one agonizing bureaucratic step at a time."*

---

## Table of Contents

1. [What Is This Game?](#what-is-this-game)
2. [How to Play](#how-to-play)
3. [Reading the Screen](#reading-the-screen)
4. [The Graph — Departments & Connections](#the-graph--departments--connections)
5. [Algorithm Guide](#algorithm-guide)
   - [BFS — Breadth-First Search](#bfs--breadth-first-search)
   - [DFS — Depth-First Search](#dfs--depth-first-search)
   - [Topo Sort — Kahn's Algorithm](#topo-sort--kahns-algorithm)
   - [Dijkstra — Shortest Path](#dijkstra--shortest-path)
   - [Bellman-Ford — Shortest Path](#bellman-ford--shortest-path)
   - [Prim's — Minimum Spanning Tree](#prims--minimum-spanning-tree)
   - [A* — Heuristic Search](#a--heuristic-search)
   - [Floyd-Warshall — All-Pairs Shortest Paths](#floyd-warshall--all-pairs-shortest-paths)
   - [Kruskal's — Minimum Spanning Tree](#kruskals--minimum-spanning-tree)
6. [Color Legend](#color-legend)
7. [What to Watch For](#what-to-watch-for)
8. [Comparing the Algorithms](#comparing-the-algorithms)
9. [Common Questions](#common-questions)

---

## What Is This Game?

This is an **interactive algorithm visualizer** disguised as a deeply dysfunctional
intergalactic post office.

A package has been misplaced somewhere in the Bureau's labyrinthine network of
departments. To find it (or at minimum, to generate the correct paperwork), we must
systematically explore the department network using graph algorithms.

Each algorithm approaches the problem differently:

- Some prioritize **breadth** — checking all nearby departments before going deeper.
- Some prioritize **depth** — committing to one corridor before backtracking.
- Some require processing departments **in dependency order**.
- Some find the **cheapest route** through the network.
- Some use a **heuristic estimate** to guide the search intelligently.
- Some compute **all routes simultaneously**.
- Some build the **minimum infrastructure** needed to connect every department.

The game steps through each algorithm **one decision at a time** so you can see
exactly what it's doing and why.

---

## How to Play

1. **Select an algorithm** by clicking a card on the main menu.
2. **Press "Process Next Memo"** to advance the algorithm by one step.
3. **Read the memo** in the main text area — it describes exactly what the algorithm
   just decided and why (in bureaucratic terms, obviously).
4. **Watch the graph** — nodes change color as they are discovered and processed.
   Active (frontier) nodes pulse with an amber glow. Edges flash cyan when examined.
5. **Check the structure panel** (queue/stack/distances) to see the algorithm's
   internal state.
6. When the button reads **"Algorithm Complete"**, the algorithm has finished.
7. Press **"Reset"** to restart the current algorithm from scratch.
8. Press **"< Menu"** to return to the algorithm selection screen.

**Tips:**
- Read every memo. They explain each decision in both comedic *and* algorithmic terms.
- Try running the same algorithm twice — the steps are always identical because
  the graph and start node are fixed.
- After finishing one algorithm, go back to the menu and compare it with another.
- Press **"[i] Info"** for a reference panel with complexity, structure explanation,
  and what to look for.

---

## Reading the Screen

### The Graph View (main area)
The main viewport shows the six departments as **colored boxes** connected by
**directed arrows**. Edge weights are shown as numbers next to each arrow.
Arrows show the direction memos can travel — you cannot go backward against an arrow.

A **twinkling starfield** and three nebula clouds render behind the graph.

### The Header Row
Shows two chips:
- **AlgoChip** — the current algorithm's form code (e.g., `BFS-9A`)
- **StepChip** — the current step number (e.g., `STEP 3`)

### The Controls Row
- **Reset** — restart the current algorithm from scratch (does not return to menu)
- **[i] Info** — toggle the reference panel covering the graph area

### The Memo Area
The large text block describes exactly what the algorithm just did — framed as an
internal memo from the algorithm to the Bureau's staff.

### The Structure Panel
Shows the algorithm's internal data structure — the queue, stack, priority queue,
distance table, or edge candidate list, depending on the algorithm. The label above
it changes per algorithm.

### The Advance Button
Each press executes exactly **one step** of the algorithm. When the algorithm finishes,
the button disables and reads "Algorithm Complete".

---

## The Graph — Departments & Connections

The Bureau consists of six departments. Mail always starts at **Dept. of Redundancy
Dept.** and (ideally) ends at **Actual Mail Delivery\***.

```
        Dept. of Redundancy Dept.
               (start)
              /         \
        cost 3           cost 1
            /               \
  Bureau of            Office of
  Unnecessary          Perpetual
  Forms                Delays
     /      \               \
 cost 8    cost -2         cost 6
   /           \               \
Division of   Archives of Misplaced
Rubber Stamps      Items
      \             /
    cost 1       cost 4
        \         /
      Actual Mail Delivery*
           (end)
```

### Edge Weights

Each connection between departments has a **cost** (shown on the arrow in-game):

| From | To | Cost | Notes |
|---|---|---|---|
| Dept. of Redundancy Dept. | Bureau of Unnecessary Forms | 3 | Standard routing |
| Dept. of Redundancy Dept. | Office of Perpetual Delays | 1 | Surprisingly cheap |
| Bureau of Unnecessary Forms | Division of Rubber Stamps | 8 | Very expensive |
| Bureau of Unnecessary Forms | Archives of Misplaced Items | **-2** | Negative — a bureaucratic rebate of sorts |
| Office of Perpetual Delays | Archives of Misplaced Items | 6 | Slow but steady |
| Division of Rubber Stamps | Actual Mail Delivery\* | 1 | Quick final step |
| Archives of Misplaced Items | Actual Mail Delivery\* | 4 | Final delivery |

The **-2 edge** (Bureau of Unnecessary Forms -> Archives of Misplaced Items) is the
most interesting feature of this graph. It represents a negative processing cost —
perhaps a bureaucratic rebate, a temporal anomaly, or a paperwork shortcut so efficient
it actually *saves* resources. Bellman-Ford and Floyd-Warshall can exploit it;
Dijkstra and A* cannot (they use the absolute value `2`).

---

## Algorithm Guide

### BFS — Breadth-First Search
**Form Code:** BFS-9A | **Category:** Traversal | **Difficulty:** *

**The Idea:** Explore the network **level by level**, checking all departments one hop
away before checking departments two hops away. This guarantees finding the
**fewest-hop** path to any department — but ignores edge costs entirely.

**Data Structure:** A **queue** (FIFO — First In, First Out). The first department
added is the first department processed.

**Step-by-step:**
1. Add the starting department to the queue and mark it as discovered (amber glow).
2. Remove the front of the queue. Mark it as visited (grey). Examine its neighbors.
3. For each unvisited neighbor: add it to the queue and mark it as discovered.
4. Repeat from step 2 until the queue is empty.

**What you'll see:** The graph lights up in "waves" — first the departments directly
connected to the start, then the departments connected to *those*, and so on.
BFS never dives deep before exploring broadly. Edges flash cyan as they are examined.

**Traversal order in this graph:**
```
redundancy -> forms -> delays -> stamps -> lost -> destination
```

**What BFS does NOT do:** Care about edge weights. A path costing 1000 and a path
costing 1 are treated equally as long as they have the same number of hops.

---

### DFS — Depth-First Search
**Form Code:** DFS-2B | **Category:** Traversal | **Difficulty:** *

**The Idea:** Pick a corridor and **follow it as deep as possible** before backtracking.
This is how you might explore a maze — commit to one path until you hit a dead end,
then try another.

**Data Structure:** A **stack** (LIFO — Last In, First Out). The most recently added
department is processed first. The structure panel shows the stack from top (next to
process) to bottom.

**Step-by-step:**
1. Push the starting department onto the stack and mark it as discovered (amber).
2. Pop the top of the stack. If already visited (stale entry), skip it.
3. Otherwise: mark it as visited (grey), examine its neighbors, push each unvisited
   neighbor onto the stack.
4. Repeat from step 2 until the stack is empty.

**What you'll see:** The algorithm dives deep into one branch before coming back.
Unlike BFS's level-by-level waves, DFS races down corridors. Edges flash cyan as examined.

**Traversal order in this graph:**
```
redundancy -> delays -> lost -> destination -> forms -> stamps
```
*(Note: DFS visits delays before forms because delays is pushed last onto the stack
and therefore sits on top — LIFO means it is processed next.)*

**Stale entries:** Because nodes are marked visited when *popped* (not when pushed),
the same node can appear on the stack multiple times if multiple paths lead to it.
When a stale copy is popped, the memo will say "STALE MEMO INTERCEPTED" and discard
it. This is normal DFS behavior.

**Comparison with BFS:** Same nodes visited (all reachable ones), different order.
DFS finishes one branch completely before starting another.

---

### Topo Sort — Kahn's Algorithm
**Form Code:** TOPO-7K | **Category:** Ordering | **Difficulty:** **

**The Idea:** Order all departments so that every department is processed *before*
the departments it connects to. In other words: **no department is processed before
its prerequisites are cleared**.

This is called a **topological ordering** and only works on **directed acyclic graphs**
(DAGs — graphs with no cycles). Our Bureau graph qualifies.

**Data Structure:** A **zero-in-degree queue** — departments with no unprocessed
incoming connections are eligible to be processed.

**In-degree:** The number of other departments that have a direct connection *into*
a department. A department with in-degree 0 has no prerequisites.

**Step-by-step:**
1. Count the in-degree of every department.
2. Add all departments with in-degree 0 to the queue.
3. Remove one department from the queue. Process it. For each of its neighbors,
   decrement that neighbor's in-degree by 1. If a neighbor reaches in-degree 0,
   add it to the queue.
4. Repeat until the queue is empty.

**What you'll see:** Only `redundancy` starts in the queue (nothing points to it).
After processing it, `forms` and `delays` both become eligible. Processing `forms`
eventually enables `stamps` and `lost`. And so on. Edges flash when in-degrees are decremented.

**Topological order in this graph:**
```
redundancy -> forms -> delays -> stamps -> lost -> destination
```

**Why does this matter?** Topological sort is used in build systems (compile A before B),
task scheduling (complete prerequisite tasks first), and course prerequisites (take
Intro CS before Advanced CS).

**Cycle detection:** If the queue empties before all departments are processed, a
cycle exists and there is no valid topological order. The memo will report this.

---

### Dijkstra — Shortest Path
**Form Code:** DIJ-1138 | **Category:** Shortest Path | **Difficulty:** **

**The Idea:** Find the **lowest-cost path** from the start to every other department,
processing departments in order of their current known best distance.

**Important caveat:** Dijkstra's algorithm requires **non-negative edge weights**.
In this game, the `-2` edge is converted to `abs(-2) = 2` before Dijkstra processes
it. This is why Dijkstra finds a different (more expensive) answer than Bellman-Ford.

**Data Structure:** A **priority queue** — always processes the unvisited department
with the lowest current cost next. Shown in the structure panel as `[cost] — Dept`.

**Step-by-step:**
1. Set start department cost to 0, all others to infinity. Add start to priority queue.
2. Extract the department with the lowest cost from the PQ.
3. For each unvisited neighbor: calculate the cost to reach it through the current
   department. If it's lower than the known cost, update it and add to PQ.
4. Repeat until PQ is empty.

**Lazy deletion:** When a cheaper path to a department is found, the old PQ entry
is not removed — instead it's left as a stale entry. When a stale entry is extracted
from the top, the memo reports "STALE ENTRY DETECTED" and discards it.

**Shortest path found (using abs weights):**
```
redundancy -> forms -> lost -> destination
Total cost: 3 + 2 + 4 = 9
```

**What you'll see:** Departments are finalized in cost order. Low-cost paths are
locked in before higher-cost ones. The priority queue grows and shrinks as cheaper
paths are discovered.

---

### Bellman-Ford — Shortest Path
**Form Code:** BF-404 | **Category:** Shortest Path | **Difficulty:** ***

**The Idea:** Find the **lowest-cost path** by repeatedly scanning *every edge* in
the graph, relaxing distances whenever a cheaper route is found. Unlike Dijkstra,
Bellman-Ford handles **negative edge weights** correctly.

**Data Structure:** A flat **edge list** (all 7 directed edges). One edge is relaxed
per step. The structure panel shows current known distances to all departments.

**Step-by-step:**
1. Set start cost to 0, all others to infinity.
2. Run `|V| - 1 = 5` passes over all edges.
3. In each pass: for each edge (A -> B, weight W), if `cost[A] + W < cost[B]`,
   update `cost[B]` and record that B is now reached via A.
4. If a full pass makes no updates, stop early — the algorithm has converged.

**Early termination:** In this graph, convergence happens after just **2 passes**
because the graph is shallow. After pass 2, no distances improve.

**Shortest path found (using raw weights including -2):**
```
redundancy -> forms -> lost -> destination
Total cost: 3 + (-2) + 4 = 5
```

**Contrast with Dijkstra:** Dijkstra with abs weights finds cost 9.
Bellman-Ford with the real -2 edge finds cost 5. This demonstrates why negative
weights matter and why Dijkstra can't handle them.

**Negative cycle detection:** If distances kept improving pass after pass, it would
indicate a negative cycle (a loop where each traversal reduces total cost infinitely).
Our graph has no negative cycles, as the completion memo confirms.

**What you'll see:** The distance table updates with each edge relaxation. Initially
most departments show infinity. After the first edge that reaches a department fires, it
gets a finite cost. Subsequent passes may improve some costs further.

---

### Prim's — Minimum Spanning Tree
**Form Code:** MST-42 | **Category:** Spanning Tree | **Difficulty:** ***

**The Idea:** Find the **cheapest set of connections** that links every department
together with no loops. This is a **Minimum Spanning Tree (MST)** — a tree that
spans all nodes with minimum total edge weight.

**Key differences from shortest-path algorithms:**
- The graph is treated as **undirected** — connections work both ways.
- All weights use `abs()` — negative weights become positive.
- The goal is not a single path but a **spanning tree** connecting all 6 departments.
- There can be no cycles in the result.

**Data Structure:** A **priority queue** of candidate connections. Shown as `[cost] — Dept`.

**Step-by-step:**
1. Start with the starting department in the MST (cost 0). All others: infinity.
2. Extract the non-MST department with the lowest connection cost.
3. Add it to the MST. For each of its neighbors not yet in the MST: if this
   department offers a cheaper connection than previously known, update the cost.
4. Repeat until all departments are in the MST.

**MST result for this graph:**

| Edge | Cost |
|---|---|
| Dept. of Redundancy Dept. <-> Office of Perpetual Delays | 1 |
| Division of Rubber Stamps <-> Actual Mail Delivery\* | 1 |
| Bureau of Unnecessary Forms <-> Archives of Misplaced Items | 2 |
| Dept. of Redundancy Dept. <-> Bureau of Unnecessary Forms | 3 |
| Archives of Misplaced Items <-> Actual Mail Delivery\* | 4 |
| **Total MST Weight** | **11** |

**What you'll see:** Departments are added to the MST one by one (visited = in MST).
The candidate queue shrinks as departments join. Stale entries appear when a cheaper
connection to a department is found — the old entry is skipped when popped.

---

### A* — Heuristic Search
**Form Code:** ASTAR-H1 | **Category:** Heuristic Search | **Difficulty:** ***

**The Idea:** Find the **lowest-cost path** from start to destination using a
**heuristic** — an estimate of the remaining cost to the goal. A* prioritizes nodes
that appear to be on the best path, not just the cheapest node explored so far.

A* uses: `f(n) = g(n) + h(n)` where:
- `g(n)` = actual cost from start to node n
- `h(n)` = estimated cost from n to destination (the heuristic)
- `f(n)` = total estimated path cost through n

Like Dijkstra, A* uses `abs(weight)` on all edges.

**Data Structure:** An **OPEN set** — nodes discovered but not yet finalized, sorted
by `f(n)`. Shown as `[f=N g=M] — DeptName`.

**Heuristic values used in this game:**

| Department | h value | Notes |
|---|---|---|
| Dept. of Redundancy Dept. | 5 | Estimated abs-cost to destination |
| Bureau of Unnecessary Forms | 6 | Estimated abs-cost to destination |
| Office of Perpetual Delays | **10** | High estimate — keeps this branch deprioritized |
| Division of Rubber Stamps | 1 | Very close to destination (cost 1 edge away) |
| Archives of Misplaced Items | 4 | One edge away (cost 4) |
| Actual Mail Delivery\* | 0 | At destination |

The heuristic is **admissible** — it never overestimates the true cost. This
guarantees A* finds the optimal path.

**Step-by-step:**
1. Add start to OPEN set with f=h, g=0.
2. Extract the node with lowest f from OPEN. Move it to CLOSED.
3. For each neighbor: compute g = g(current) + edge_cost, f = g + h(neighbor).
   If better than known, add/update in OPEN.
4. Repeat until destination is extracted to CLOSED.

**What you'll see:** A* tends to focus on nodes with low f values — nodes that are
both cheaply reachable *and* close to the goal. Notice how `delays` (h=10) is avoided
until much later than in Dijkstra — the high heuristic keeps it off the priority path.

**Path found:**
```
redundancy -> forms -> lost -> destination
Total cost: 3 + 2 + 4 = 9  (same as Dijkstra — both use abs weights)
```

**Comparison with Dijkstra:** Same path, same cost. But A* reaches the answer by
exploring fewer nodes — it skips dead-end branches that Dijkstra must also check.
On larger graphs with good heuristics, this difference becomes dramatic.

---

### Floyd-Warshall — All-Pairs Shortest Paths
**Form Code:** FW-INF | **Category:** All-Pairs Path | **Difficulty:** ***

**The Idea:** Compute the **shortest path between every pair of departments** in a
single sweep. Instead of finding one path from one source, Floyd-Warshall finds them
all simultaneously — a complete distance matrix.

Like Bellman-Ford, Floyd-Warshall uses **real weights including the -2 edge**.

**No individual node traversal:** Floyd-Warshall operates on a global matrix. No
departments are colored during execution — the algorithm has no concept of "visiting"
one node at a time.

**Data Structure:** A 6×6 **distance matrix** `dist[i][j]` = shortest known path from
department i to department j. Structure panel shows `dist[node][destination]` for
each department, updated after each iteration.

**Step-by-step (the relaxation idea):**
For each intermediate node k (in order):
  For every pair (i, j):
    If `dist[i][k] + dist[k][j] < dist[i][j]`:
      Update `dist[i][j]` (routing through k is cheaper)

**Step-by-step in this game (6 iterations):**
1. k=redundancy — routes through redundancy improve some distant pairs
2. k=forms — dist[redundancy][lost] drops from INF to **1** (3 + -2 = 1!)
3. k=delays — routes through delays fill in
4. k=stamps — routes through stamps fill in
5. k=lost — dist[redundancy][destination] drops to **5** (dist[red][lost]=1, + 4 = 5)
6. k=destination — completes the matrix; final answer confirmed

**Key educational moment:** Watch the structure panel after step 2 (k=forms). The
redundancy->destination entry updates. By step 5, it shows 5 — the correct answer
using the real -2 edge, proving that routing through forms and lost is cheaper.

**Comparison with Bellman-Ford:** Both find the cost-5 path using the real -2 weight.
The difference is *scope*: Bellman-Ford finds the shortest path from one source.
Floyd-Warshall finds shortest paths between **all** source-destination pairs at once.

---

### Kruskal's — Minimum Spanning Tree
**Form Code:** KRU-7F | **Category:** Spanning Tree | **Difficulty:** **

**The Idea:** Build the MST by sorting **all edges in the entire graph** by cost and
greedily picking the cheapest edge that doesn't create a cycle. This is the opposite
strategy to Prim's — instead of growing outward from one node, Kruskal considers the
globally cheapest remaining edge at every step.

Uses `abs(weight)` on all edges. Graph treated as undirected.

**Cycle detection:** Uses **Union-Find** (also called Disjoint Set Union) — a data
structure that efficiently tracks which nodes are already connected. If both endpoints
of an edge are in the same component, adding that edge would create a cycle, so it
is rejected.

**Data Structure:** A sorted list of **candidate edges**, consumed from cheapest to
most expensive. Shown as `[W] NodeA | NodeB`.

**Sorted edges in this graph:**

| Cost | Edge | Result |
|---|---|---|
| 1 | redundancy <-> delays | Accept (connects two components) |
| 1 | stamps <-> destination | Accept (connects two components) |
| 2 | forms <-> lost | Accept (connects two components) |
| 3 | redundancy <-> forms | Accept (connects two larger components) |
| 4 | lost <-> destination | Accept (final edge — MST complete) |
| 6 | delays <-> lost | Would be next, but MST is already complete |
| 8 | forms <-> stamps | Would be next, but MST is already complete |

**What you'll see:** Edges are considered one at a time in sorted order. When an edge
is accepted, both endpoints light up amber (frontier), then on the next step turn grey
(in MST). Examined edges flash cyan.

**MST result:**

| Edge | Cost |
|---|---|
| redundancy <-> delays | 1 |
| stamps <-> destination | 1 |
| forms <-> lost | 2 |
| redundancy <-> forms | 3 |
| lost <-> destination | 4 |
| **Total MST Weight** | **11** |

**Comparison with Prim's:** Both find the same MST with total weight 11. The
difference is strategy:
- **Prim's** grows outward from one starting node, always taking the cheapest edge
  adjacent to the current MST.
- **Kruskal's** sorts all edges globally and greedily picks the cheapest non-cycle
  edge anywhere in the graph.

Both are valid and both produce optimal MSTs. In practice, Prim's is faster on
dense graphs; Kruskal's is faster on sparse graphs.

---

## Color Legend

| Color | Meaning |
|---|---|
| **Dark (default)** | This department has not been discovered yet |
| **Amber / gold (pulsing)** | In the active data structure — discovered but not fully processed. Pulses with a breathing glow. |
| **Charcoal grey** | Fully processed / finalized / added to MST |

**Edges:** When an algorithm examines an edge, it **flashes cyan** briefly, then
returns to its normal color. This highlights which connection the algorithm just
considered.

The **dark badge** at the top of each node shows the department's short ID code (in
caps). The **white text** shows the full department name.

---

## What to Watch For

### BFS vs. DFS
Run BFS, note the order in which nodes turn grey. Then reset, switch to DFS, and run
it. Watch how DFS dives into the `delays -> lost -> destination` corridor completely
before circling back to process `forms`. BFS spreads level by level; DFS races to depth.

### Dijkstra vs. Bellman-Ford
Both algorithms find a path. Dijkstra finds cost **9** (treating the -2 edge as +2).
Bellman-Ford finds cost **5** (using the real -2). The final memo for each algorithm
shows the winning path — compare them. The exact same physical path leads to two
different costs depending on whether the algorithm honors negative weights.

### Dijkstra vs. A*
Both use abs weights and both find the cost-9 path. The difference is efficiency.
Watch how A* handles the `delays` branch (h=10) — it assigns a high f-value to that
node, keeping it near the bottom of the priority queue until other options run out.
Dijkstra has no such guidance and explores more neutrally.

### Bellman-Ford vs. Floyd-Warshall
Both use the real -2 edge and both find the cost-5 path. The difference is scope.
Bellman-Ford works from one starting point. Floyd-Warshall computes *all* shortest
paths at once — watch the structure panel update with all six entries simultaneously
as each k-iteration runs.

### Prim's vs. Kruskal's
Both produce the same MST with total weight 11. Run Prim's first, note the order
in which departments are added. Then run Kruskal's. Prim's grows from `redundancy`
outward — it sees the `delays` edge first (cost 1). Kruskal's sorts all edges globally
and also picks the two cost-1 edges first, but in a different conceptual way.

### Topo Sort's In-Degrees
At initialization, the memo shows the in-degree of every department. Watch how
processing one department decrements the in-degree of its neighbors. When a neighbor
hits 0, it joins the queue and turns amber — it is now "ready to process" because
all its prerequisites have been cleared.

### Stale Entries
In DFS, Dijkstra, A*, and Prim's, the algorithm leaves outdated entries in the stack or
priority queue rather than removing them immediately. When a stale entry is encountered,
the memo calls it out explicitly. This "lazy deletion" approach is a classic
implementation trick — trading memory for implementation simplicity.

---

## Comparing the Algorithms

| Algorithm | Weights | Structure | Finds | Handles Negatives? |
|---|---|---|---|---|
| BFS | Ignored | Queue (FIFO) | Fewest-hop path | N/A |
| DFS | Ignored | Stack (LIFO) | Any path (depth-first) | N/A |
| Topo Sort | Ignored | Zero-in-degree queue | Valid processing order | N/A |
| Dijkstra | abs() | Priority queue (min-cost first) | Shortest path from source | No |
| Bellman-Ford | Raw (incl. -2) | Flat edge list | Shortest path from source | **Yes** |
| Prim's | abs(), undirected | Priority queue (min-edge first) | Minimum Spanning Tree | N/A |
| A* | abs() | OPEN set (min-f first) | Shortest path (heuristic-guided) | No |
| Floyd-Warshall | Raw (incl. -2) | 6x6 distance matrix | All-pairs shortest paths | **Yes** |
| Kruskal's | abs(), undirected | Sorted edge list | Minimum Spanning Tree | N/A |

### Traversal Orders (for this graph)

| Algorithm | Visit order |
|---|---|
| BFS | redundancy -> forms -> delays -> stamps -> lost -> destination |
| DFS | redundancy -> delays -> lost -> destination -> forms -> stamps |
| Topo Sort | redundancy -> forms -> delays -> stamps -> lost -> destination |
| A* | redundancy -> forms -> lost -> destination (then delays, stamps if needed) |

### Shortest Paths to Destination

| Algorithm | Path | Total Cost | Weight handling |
|---|---|---|---|
| Dijkstra | redundancy -> forms -> lost -> destination | **9** | abs(-2) = 2 |
| Bellman-Ford | redundancy -> forms -> lost -> destination | **5** | raw -2 |
| A* | redundancy -> forms -> lost -> destination | **9** | abs(-2) = 2 |
| Floyd-Warshall | redundancy -> forms -> lost -> destination | **5** | raw -2 |

### MST Results

Both Prim's and Kruskal's produce the same minimum spanning tree:

| Edge | Cost |
|---|---|
| redundancy <-> delays | 1 |
| stamps <-> destination | 1 |
| forms <-> lost | 2 |
| redundancy <-> forms | 3 |
| lost <-> destination | 4 |
| **Total MST Weight** | **11** |

---

## Common Questions

**Why does BFS visit forms before delays?**
Because `forms` is listed first in `redundancy`'s neighbor list, it is added to the
queue first. BFS processes the queue in order of insertion, so `forms` is dequeued
before `delays`.

**Why does DFS visit delays before forms?**
After processing `redundancy`, both `forms` and `delays` are pushed to the stack.
`delays` is pushed *after* `forms`, so it sits on *top* of the stack. Since the stack
is LIFO, `delays` is processed next.

**Why does Dijkstra treat the -2 edge as +2?**
Dijkstra's algorithm breaks when edge weights are negative — it can produce incorrect
results because it assumes that adding more edges to a path always increases cost. A
negative edge violates this assumption. To stay educational, this game converts all
weights to their absolute value before Dijkstra processes them, letting you see the
contrast: Bellman-Ford handles the real weight and finds the cheaper path.

**Why does A* find the same path as Dijkstra?**
Both A* and Dijkstra use abs weights in this game, so they see the same graph. A*'s
advantage over Dijkstra is *efficiency* (fewer node expansions), not path quality.
On this tiny 6-node graph, the difference is subtle. On large graphs with a good
heuristic, A* can be orders of magnitude faster than Dijkstra.

**Why does Floyd-Warshall show no node colors changing?**
Floyd-Warshall doesn't "visit" nodes one at a time — it updates the entire distance
matrix in each step. There is no concept of one node being "in the frontier" and
another being "visited". The algorithm is a global matrix operation, not a traversal.

**What would happen if there were a negative cycle?**
A negative cycle is a loop of edges whose weights sum to a negative number (e.g.,
A -> B cost -1, B -> A cost -1: each round trip reduces cost by 2, forever).
Bellman-Ford detects them by checking whether distances still decrease after
`|V| - 1` passes — if they do, a negative cycle exists.
Floyd-Warshall detects them if the diagonal of the distance matrix becomes negative
(`dist[i][i] < 0` for any i).
In our graph, there are no negative cycles, which both completion memos confirm.

**Why does Topo Sort ignore the start node?**
Topological sort isn't about starting from one node — it's about ordering *all* nodes
by dependency. Kahn's algorithm seeds the queue with *any and all* nodes that have
zero in-degree, regardless of a specific starting point.

**Why do Prim's and Kruskal's give the same MST?**
They use different strategies but both are provably optimal — they produce a valid
minimum spanning tree. Since the MST is unique when all edge weights are distinct
(which is nearly the case here), both algorithms converge to the same answer.
The difference is *how* they find it: Prim's grows a connected subgraph from one node;
Kruskal's assembles disconnected fragments by global edge sorting.

**Why does Prim's give a different result than Dijkstra?**
They optimize for different things. Dijkstra minimizes the total cost of a path *from
the start node* to each other node. Prim's minimizes the total weight of edges needed
to connect *all* nodes into one tree. The optimal set of edges for a spanning tree is
generally not the same as the optimal set of edges for a shortest-path tree.

**Is the asterisk in "Actual Mail Delivery\*" significant?**
The asterisk refers to footnote 7(b) of Inter-Bureau Regulation 44-C, which clarifies
that "Actual Mail Delivery" is subject to availability, processing delays, dimensional
anomalies, and the current position of the Galactic Postal Union's collective bargaining
agreement. The Bureau assumes no liability for mail that arrives in the wrong century.
