#define urlify1(x)        LCASE(REPLACE(REPLACE(REPLACE(x, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", ""))
#define urlify(x)         bind(urlify1(x) as x##_URLIFY)
#define fixDate(x)        bind(REPLACE(x,' ','T') as x##_FIXDATE)
#define lcase(x)          bind(LCASE(x) as x##_LCASE)
#define cb_org_url(x)     filter(bound(x)) x##_CB_ORG_URL a k2:Organization; k2:cbPermalink x
#define split1(x)         x##_SPLIT1 spif:split (x ',').
#define splitArray(x)     bind(REPLACE(x,'[\\["\\]]+','') as x##_ARRAY)  x##_SPLITARRAY spif:split (x##_ARRAY ',').
#define ifNotNull(x)      bind(if(x in ("other","not provided","unknown"),?UNDEF,x) as x##_IFNOTNULL)
#define ifNotSame(x,y)    bind(if(x=y,?UNDEF,x) as x##_IFNOTSAME)
#define booleanYesNo(x)   bind(if(x="Yes",true,false) as x##_BOOLEANYESNO)
#define coalesce(x,...)   bind(COALESCE(__VA_ARGS__) as x##_COALESCE)

#define STRINGIZE(x)      #x                               // Any " in x are escaped, but using ' is preferred to avoid escaping
#define GREL(x,y)         (1 STRINGIZE(x)) mapper:grel ?y. // first value doesn't matter
