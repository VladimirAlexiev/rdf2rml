#define __IF_BOUND_1(x,y1)             bind(if(bound(?y1),#x,?UNDEF) as ?x##_IF_BOUND)
#define __IF_BOUND_2(x,y1,y2)          bind(if(bound(?y1)||bound(?y2),#x,?UNDEF) as ?x##_IF_BOUND)
#define __IF_BOUND_3(x,y1,y2,y3)       bind(if(bound(?y1)||bound(?y2)||bound(?y3),#x,?UNDEF) as ?x##_IF_BOUND)
#define __IF_BOUND_4(x,y1,y2,y3,y4)    bind(if(bound(?y1)||bound(?y2)||bound(?y3)||bound(?y4),#x,?UNDEF) as ?x##_IF_BOUND)
#define __IF_BOUND_5(x,y1,y2,y3,y4,y5) bind(if(bound(?y1)||bound(?y2)||bound(?y3)||bound(?y4)||bound(?y5),#x,?UNDEF) as ?x##_IF_BOUND)

#define __IF_BOUND_PICK_N(_1,_2,_3,_4,_5,N,...) __IF_BOUND_##N
#define _IF_BOUND(x,...) __IF_BOUND_PICK_N(__VA_ARGS__,5,4,3,2,1)(x,__VA_ARGS__)
