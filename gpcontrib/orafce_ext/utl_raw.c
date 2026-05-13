/*
 * utl_raw.c
 *
 * Oracle UTL_RAW package implementation for orafce_ext.
 * Provides binary data (RAW) manipulation functions.
 */

#include "postgres.h"

#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(utl_raw_cast_to_raw);
PG_FUNCTION_INFO_V1(utl_raw_cast_to_varchar2);
PG_FUNCTION_INFO_V1(utl_raw_concat);
PG_FUNCTION_INFO_V1(utl_raw_convert);
PG_FUNCTION_INFO_V1(utl_raw_length);
PG_FUNCTION_INFO_V1(utl_raw_substr);

/* Oracle-to-PostgreSQL character set name mapping */
typedef struct
{
	const char *oracle_name;
	const char *pg_name;
} CharsetMapping;

static const CharsetMapping charset_map[] = {
	{"AL32UTF8",		"UTF8"},
	{"UTF8",			"UTF8"},
	{"UTF-8",			"UTF8"},
	{"ZHS16GBK",		"GBK"},
	{"ZHS32GB18030",	"GB18030"},
	{"JA16SJIS",		"SJIS"},
	{"JA16SJISTILDE",	"SJIS"},
	{"JA16EUC",			"EUC_JP"},
	{"JA16EUCTILDE",	"EUC_JP"},
	{"KO16KSC5601",		"EUC_KR"},
	{"KO16MSWIN949",	"UHC"},
	{"ZHT16BIG5",		"BIG5"},
	{"ZHT32EUC",		"EUC_TW"},
	{"WE8ISO8859P1",	"LATIN1"},
	{"WE8ISO8859P2",	"LATIN2"},
	{"WE8ISO8859P3",	"LATIN3"},
	{"WE8ISO8859P4",	"LATIN4"},
	{"WE8ISO8859P9",	"LATIN5"},
	{"WE8ISO8859P10",	"LATIN6"},
	{"WE8ISO8859P13",	"LATIN7"},
	{"WE8ISO8859P14",	"LATIN8"},
	{"WE8ISO8859P15",	"LATIN9"},
	{"WE8ISO8859P16",	"LATIN10"},
	{"US7ASCII",		"SQL_ASCII"},
	{"WE8MSWIN1252",	"WIN1252"},
	{"EE8MSWIN1250",	"WIN1250"},
	{"CL8MSWIN1251",	"WIN1251"},
	{"EL8MSWIN1253",	"WIN1253"},
	{"TR8MSWIN1254",	"WIN1254"},
	{"IW8MSWIN1255",	"WIN1255"},
	{"AR8MSWIN1256",	"WIN1256"},
	{"BLT8MSWIN1257",	"WIN1257"},
	{"VN8MSWIN1258",	"WIN1258"},
	{NULL,				NULL}
};

/*
 * Map an Oracle character set name to its PostgreSQL equivalent.
 * Returns the original name if no mapping is found (passthrough for PG names).
 */
static const char *
oracle_charset_to_pg(const char *oracle_name)
{
	int	i;

	for (i = 0; charset_map[i].oracle_name != NULL; i++)
	{
		if (pg_strcasecmp(charset_map[i].oracle_name, oracle_name) == 0)
			return charset_map[i].pg_name;
	}
	return oracle_name;
}

/*
 * utl_raw_cast_to_raw(varchar2) → raw
 *
 * Reinterprets the byte sequence of a VARCHAR2 value as RAW without any
 * character set conversion.
 */
Datum
utl_raw_cast_to_raw(PG_FUNCTION_ARGS)
{
	text	   *input = PG_GETARG_TEXT_PP(0);
	int			len = VARSIZE_ANY_EXHDR(input);
	bytea	   *result = (bytea *) palloc(VARHDRSZ + len);

	SET_VARSIZE(result, VARHDRSZ + len);
	memcpy(VARDATA(result), VARDATA_ANY(input), len);

	PG_RETURN_BYTEA_P(result);
}

/*
 * utl_raw_cast_to_varchar2(raw) → varchar2
 *
 * Reinterprets the bytes of a RAW value as VARCHAR2 without any character
 * set conversion.
 */
Datum
utl_raw_cast_to_varchar2(PG_FUNCTION_ARGS)
{
	bytea	   *input = PG_GETARG_BYTEA_PP(0);
	int			len = VARSIZE_ANY_EXHDR(input);
	text	   *result = (text *) palloc(VARHDRSZ + len);

	SET_VARSIZE(result, VARHDRSZ + len);
	memcpy(VARDATA(result), VARDATA_ANY(input), len);

	PG_RETURN_TEXT_P(result);
}

/*
 * utl_raw_length(raw) → integer
 *
 * Returns the number of bytes in a RAW value.
 */
Datum
utl_raw_length(PG_FUNCTION_ARGS)
{
	bytea	   *r = PG_GETARG_BYTEA_PP(0);

	PG_RETURN_INT32(VARSIZE_ANY_EXHDR(r));
}

/*
 * utl_raw_substr(raw, pos, len) → raw
 *
 * Returns a substring of a RAW value using Oracle semantics:
 *   - pos is 1-based; negative values count backward from the end
 *   - pos cannot be 0 or beyond the value's bounds
 *   - len is optional (NULL means "to the end")
 *   - len must be >= 1
 */
Datum
utl_raw_substr(PG_FUNCTION_ARGS)
{
	bytea	   *r;
	int32		pos;
	bool		len_is_null = PG_ARGISNULL(2);
	int32		len = len_is_null ? 0 : PG_GETARG_INT32(2);
	int32		r_len,
				start,
				count;
	bytea	   *result;

	/* NULL r or NULL pos → NULL result */
	if (PG_ARGISNULL(0) || PG_ARGISNULL(1))
		PG_RETURN_NULL();

	r = PG_GETARG_BYTEA_PP(0);
	pos = PG_GETARG_INT32(1);
	r_len = VARSIZE_ANY_EXHDR(r);

	if (r_len == 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("UTL_RAW.SUBSTR: input RAW is empty")));

	if (pos == 0 || pos > r_len || pos < -r_len)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("UTL_RAW.SUBSTR: \"pos\" is out of range")));

	if (pos > 0)
		start = pos - 1;		/* convert 1-based to 0-based */
	else
		start = r_len + pos;	/* negative: count backward from end */

	if (len_is_null)
	{
		count = r_len - start;
	}
	else
	{
		if (len < 1)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("UTL_RAW.SUBSTR: \"len\" must be at least 1")));
		count = Min(len, r_len - start);
	}

	result = (bytea *) palloc(VARHDRSZ + count);
	SET_VARSIZE(result, VARHDRSZ + count);
	memcpy(VARDATA(result), VARDATA_ANY(r) + start, count);

	PG_RETURN_BYTEA_P(result);
}

/*
 * utl_raw_concat(VARIADIC raw[]) → raw
 *
 * Concatenates multiple RAW values into a single RAW value.
 * NULL elements are silently skipped (Oracle behavior).
 */
Datum
utl_raw_concat(PG_FUNCTION_ARGS)
{
	ArrayType  *arr;

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	arr = PG_GETARG_ARRAYTYPE_P(0);
	Datum	   *elements;
	bool	   *nulls;
	int			nelems;
	int			i;
	int			total_len = 0;
	bytea	   *result;
	char	   *p;
	int16		typlen;
	bool		typbyval;
	char		typalign;

	get_typlenbyvalalign(ARR_ELEMTYPE(arr), &typlen, &typbyval, &typalign);
	deconstruct_array(arr, ARR_ELEMTYPE(arr), typlen, typbyval, typalign,
					  &elements, &nulls, &nelems);

	/* First pass: compute total output length, skipping NULLs */
	for (i = 0; i < nelems; i++)
	{
		if (!nulls[i])
		{
			bytea *b = DatumGetByteaPP(elements[i]);
			total_len += VARSIZE_ANY_EXHDR(b);
		}
	}

	result = (bytea *) palloc(VARHDRSZ + total_len);
	SET_VARSIZE(result, VARHDRSZ + total_len);
	p = VARDATA(result);

	/* Second pass: copy element data */
	for (i = 0; i < nelems; i++)
	{
		if (!nulls[i])
		{
			bytea  *b = DatumGetByteaPP(elements[i]);
			int		len = VARSIZE_ANY_EXHDR(b);

			memcpy(p, VARDATA_ANY(b), len);
			p += len;
		}
	}

	PG_RETURN_BYTEA_P(result);
}

/*
 * utl_raw_convert(raw, to_charset, from_charset) → raw
 *
 * Converts RAW data from one character set to another.
 * Accepts both Oracle-style names (AL32UTF8, ZHS16GBK) and
 * PostgreSQL/iconv-style names (UTF8, GBK) for flexibility.
 */
Datum
utl_raw_convert(PG_FUNCTION_ARGS)
{
	bytea	   *r = PG_GETARG_BYTEA_PP(0);
	char	   *to_name = text_to_cstring(PG_GETARG_TEXT_PP(1));
	char	   *from_name = text_to_cstring(PG_GETARG_TEXT_PP(2));
	const char *pg_to = oracle_charset_to_pg(to_name);
	const char *pg_from = oracle_charset_to_pg(from_name);
	int			src_enc,
				dst_enc;
	unsigned char *src,
			   *dst;
	int			srclen,
				dstlen;
	bytea	   *result;

	src_enc = pg_char_to_encoding(pg_from);
	if (src_enc < 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("UTL_RAW.CONVERT: invalid source character set \"%s\"",
						from_name)));

	dst_enc = pg_char_to_encoding(pg_to);
	if (dst_enc < 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("UTL_RAW.CONVERT: invalid destination character set \"%s\"",
						to_name)));

	src = (unsigned char *) VARDATA_ANY(r);
	srclen = VARSIZE_ANY_EXHDR(r);

	dst = pg_do_encoding_conversion(src, srclen, src_enc, dst_enc);

	/*
	 * When src_enc == dst_enc, pg_do_encoding_conversion returns src itself
	 * without allocating a new buffer.  src is not null-terminated (it's the
	 * interior of a bytea varlena), so strlen() would read past the end.
	 * Use srclen directly in that case.
	 */
	dstlen = (dst != src) ? strlen((char *) dst) : srclen;

	result = (bytea *) palloc(VARHDRSZ + dstlen);
	SET_VARSIZE(result, VARHDRSZ + dstlen);
	memcpy(VARDATA(result), dst, dstlen);

	if (dst != src)
		pfree(dst);

	PG_RETURN_BYTEA_P(result);
}
