edges=[(1,0)]
order=[0,1]
print("naive order",order)
assert all(order.index(a)<order.index(b) for a,b in edges), "vertex-number order violates dependency"
