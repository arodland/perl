#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ext/dbm/sdbm/sdbm.h"

typedef DBM* SDBM_File;
#define sdbm_new(dbtype,filename,flags,mode) sdbm_open(filename,flags,mode)

static int
XS_SDBM_File_sdbm_new(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 4 || items > 4) {
	fatal("Usage: SDBM_File::new(dbtype, filename, flags, mode)");
    }
    {
	char *	dbtype = SvPV(ST(1),na);
	char *	filename = SvPV(ST(2),na);
	int	flags = (int)SvIV(ST(3));
	int	mode = (int)SvIV(ST(4));
	SDBM_File	RETVAL;

	RETVAL = sdbm_new(dbtype, filename, flags, mode);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setptrobj(ST(0), RETVAL, "SDBM_File");
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_DESTROY(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: SDBM_File::DESTROY(db)");
    }
    {
	SDBM_File	db;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");
	sdbm_close(db);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_fetch(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	fatal("Usage: SDBM_File::fetch(db, key)");
    }
    {
	SDBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = sdbm_fetch(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_store(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 3 || items > 4) {
	fatal("Usage: SDBM_File::store(db, key, value, flags = DBM_REPLACE)");
    }
    {
	SDBM_File	db;
	datum	key;
	datum	value;
	int	flags;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	value.dptr = SvPV(ST(3), value.dsize);;

	if (items < 4)
	    flags = DBM_REPLACE;
	else {
	    flags = (int)SvIV(ST(4));
	}

	RETVAL = sdbm_store(db, key, value, flags);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_delete(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	fatal("Usage: SDBM_File::delete(db, key)");
    }
    {
	SDBM_File	db;
	datum	key;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = sdbm_delete(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_firstkey(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: SDBM_File::firstkey(db)");
    }
    {
	SDBM_File	db;
	datum	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	RETVAL = sdbm_firstkey(db);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_nextkey(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	fatal("Usage: SDBM_File::nextkey(db, key)");
    }
    {
	SDBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = sdbm_nextkey(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_error(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: SDBM_File::error(db)");
    }
    {
	SDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	RETVAL = sdbm_error(db);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_SDBM_File_sdbm_clearerr(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: SDBM_File::clearerr(db)");
    }
    {
	SDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File"))
	    db = (SDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type SDBM_File");

	RETVAL = sdbm_clearerr(db);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

int init_SDBM_File(ix,sp,items)
int ix;
int sp;
int items;
{
    char* file = __FILE__;

    newXSUB("SDBM_File::new", 0, XS_SDBM_File_sdbm_new, file);
    newXSUB("SDBM_File::DESTROY", 0, XS_SDBM_File_sdbm_DESTROY, file);
    newXSUB("SDBM_File::fetch", 0, XS_SDBM_File_sdbm_fetch, file);
    newXSUB("SDBM_File::store", 0, XS_SDBM_File_sdbm_store, file);
    newXSUB("SDBM_File::delete", 0, XS_SDBM_File_sdbm_delete, file);
    newXSUB("SDBM_File::firstkey", 0, XS_SDBM_File_sdbm_firstkey, file);
    newXSUB("SDBM_File::nextkey", 0, XS_SDBM_File_sdbm_nextkey, file);
    newXSUB("SDBM_File::error", 0, XS_SDBM_File_sdbm_error, file);
    newXSUB("SDBM_File::clearerr", 0, XS_SDBM_File_sdbm_clearerr, file);
}
