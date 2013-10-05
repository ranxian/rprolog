mother(alice, paul).
father(paul, peter).
father(paul, sam).
grandmother(X, Y) :- father(Z, Y), mother(X, Z).