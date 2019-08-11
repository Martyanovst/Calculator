set -eu
as calc.s -o object.o
as postfixNotation.s -o object1.o
as calculate.s -o object2.o
ld object.o object1.o object2.o -o compiled
chmod +x compiled 
./compiled
rm object.o
rm object1.o
rm object2.o
rm compiled