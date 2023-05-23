from z3 import *

# Assuming X, Y, P, DX, DY, P1, P2 are integer variables.
X, Y, P, DX, DY, P1, P2 = Ints('X Y P DX DY P1 P2')
X1, Y1, X2, Y2 = Ints('X1 Y1 X2 Y2')

# Function representations for the predicates.
pattern = Function('pattern', IntSort(), BoolSort())
cell = Function('cell', IntSort(), IntSort(), BoolSort())
assign = Function('assign', IntSort(), IntSort(), IntSort(), BoolSort())
adj = Function('adj', IntSort(), IntSort(), IntSort(), IntSort(), IntSort(), IntSort(), BoolSort())
legal = Function('legal', IntSort(), IntSort(), IntSort(), IntSort(), BoolSort())

# The solver
s = Solver()

# 1 { assign(X,Y,P):pattern(P) } 1 :- cell(X,Y).
# Translated into Z3, this rule can be represented as an implication:
# if cell(X,Y) is true then there exists a P such that assign(X,Y,P) is true and pattern(P) is true.
s.add(ForAll([X, Y], Implies(cell(X,Y), Exists([P], And(assign(X,Y,P), pattern(P))))))

# :- adj(X1,Y1,X2,Y2,DX,DY),
# assign(X1,Y1,P1),
# not 1 { assign(X2,Y2,P2):legal(DX,DY,P1,P2) }.
# Translated into Z3, this rule can be represented as:
# if adj(X1,Y1,X2,Y2,DX,DY) is true and assign(X1,Y1,P1) is true,
# then there exists a P2 such that assign(X2,Y2,P2) is true and legal(DX,DY,P1,P2) is true.
s.add(ForAll([X1, Y1, X2, Y2, DX, DY, P1],
              Implies(And(adj(X1,Y1,X2,Y2,DX,DY), assign(X1,Y1,P1)),
                       Exists([P2], And(assign(X2,Y2,P2), legal(DX,DY,P1,P2))))))

if s.check() == sat:
    m = s.model()
    print(m)

else:
    print("unsat")