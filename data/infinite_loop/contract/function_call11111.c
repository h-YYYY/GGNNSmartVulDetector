#include "vntlib.h"

KEY uint16 count = 10;

constructor Function1(){}

MUTABLE
uint16 test1(uint16 a){
    uint16 v = a;
    uint16 c = test2(a, v)
    return c;
}

MUTABLE
uint16 test2(uint16 b, uint16 c){
    uint16 e = U256SafeAdd(b, c);
    uint16 res = test3(e);
    return res;
}

MUTABLE
uint16 test3(uint16 a){
    uint16 res = U256SafeMul(a, count);
    return res;
}

