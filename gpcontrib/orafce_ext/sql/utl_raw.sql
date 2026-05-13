-- UTL_RAW regression tests
-- Covers normal usage and boundary conditions for all six functions.

CREATE EXTENSION IF NOT EXISTS orafce;
CREATE EXTENSION IF NOT EXISTS orafce_ext;

SET search_path = oracle, public;
\pset null '(null)'

-- ============================================================
-- utl_raw.cast_to_raw(text) → raw
-- ============================================================

-- basic ASCII string
SELECT utl_raw.cast_to_raw('abc');

-- single ASCII byte
SELECT utl_raw.cast_to_raw('A');

-- empty string → empty raw
SELECT utl_raw.cast_to_raw('');

-- NULL → NULL (STRICT)
SELECT utl_raw.cast_to_raw(NULL::text);

-- space character
SELECT utl_raw.cast_to_raw(' ');

-- oracle.varchar2 input (implicit cast to text via orafce)
SELECT utl_raw.cast_to_raw('abc'::varchar2);

-- multibyte UTF-8: 你 = U+4F60 = E4 BD A0
SELECT utl_raw.cast_to_raw('你');

-- multibyte UTF-8: two characters 你好 = E4BDA0 E5A5BD
SELECT utl_raw.cast_to_raw('你好');

-- ============================================================
-- utl_raw.cast_to_varchar2(raw) → text
-- ============================================================

-- basic ASCII bytes
SELECT utl_raw.cast_to_varchar2('\x616263'::raw);

-- single byte
SELECT utl_raw.cast_to_varchar2('\x41'::raw);

-- empty raw → empty text
SELECT utl_raw.cast_to_varchar2('\x'::raw);

-- NULL → NULL (STRICT)
SELECT utl_raw.cast_to_varchar2(NULL::raw);

-- round-trip: cast_to_raw then cast_to_varchar2
SELECT utl_raw.cast_to_varchar2(utl_raw.cast_to_raw('hello'));

-- multibyte round-trip: 你好
SELECT utl_raw.cast_to_varchar2(utl_raw.cast_to_raw('你好'));

-- ============================================================
-- utl_raw.length(raw) → integer
-- ============================================================

-- 3-byte ASCII
SELECT utl_raw.length('\x616263'::raw);

-- 1 byte
SELECT utl_raw.length('\x41'::raw);

-- empty raw → 0
SELECT utl_raw.length('\x'::raw);

-- null byte is a valid byte
SELECT utl_raw.length('\x00'::raw);

-- NULL → NULL (STRICT)
SELECT utl_raw.length(NULL::raw);

-- 4 bytes
SELECT utl_raw.length('\x61626364'::raw);

-- multibyte: 你 is 3 bytes in UTF-8
SELECT utl_raw.length(utl_raw.cast_to_raw('你'));

-- multibyte: 你好 is 6 bytes in UTF-8
SELECT utl_raw.length(utl_raw.cast_to_raw('你好'));

-- ============================================================
-- utl_raw.substr(raw, pos [, len]) → raw
-- ============================================================
-- Test data: '\x616263' = abc (3 bytes)
-- Test data: '\x6162636465' = abcde (5 bytes)

-- first byte
SELECT utl_raw.substr('\x616263'::raw, 1, 1);

-- first two bytes
SELECT utl_raw.substr('\x616263'::raw, 1, 2);

-- all bytes (len = total length)
SELECT utl_raw.substr('\x616263'::raw, 1, 3);

-- from pos 1 to end (no len)
SELECT utl_raw.substr('\x616263'::raw, 1);

-- from pos 2 to end
SELECT utl_raw.substr('\x616263'::raw, 2);

-- from pos 3 to end (last byte only)
SELECT utl_raw.substr('\x616263'::raw, 3);

-- last byte using positive pos
SELECT utl_raw.substr('\x616263'::raw, 3, 1);

-- len > remaining bytes → clamped to end
SELECT utl_raw.substr('\x616263'::raw, 2, 100);

-- middle slice of 5-byte value
SELECT utl_raw.substr('\x6162636465'::raw, 2, 3);

-- negative pos: last byte
SELECT utl_raw.substr('\x616263'::raw, -1, 1);

-- negative pos: last 2 bytes
SELECT utl_raw.substr('\x616263'::raw, -2, 2);

-- negative pos = -length: equivalent to pos=1
SELECT utl_raw.substr('\x616263'::raw, -3, 1);

-- negative pos to end (no len)
SELECT utl_raw.substr('\x616263'::raw, -2);

-- single-byte input: pos=1
SELECT utl_raw.substr('\x41'::raw, 1, 1);

-- single-byte input: pos=-1 (same as pos=1 for 1-byte input)
SELECT utl_raw.substr('\x41'::raw, -1, 1);

-- single-byte input: to end
SELECT utl_raw.substr('\x41'::raw, 1);

-- NULL r → NULL
SELECT utl_raw.substr(NULL::raw, 1, 2);

-- NULL pos → NULL
SELECT utl_raw.substr('\x616263'::raw, NULL::integer, 2);

-- NULL len → to end (same as omitting len)
SELECT utl_raw.substr('\x616263'::raw, 1, NULL::integer);

-- error: pos = 0 (forbidden by Oracle semantics)
SELECT utl_raw.substr('\x616263'::raw, 0, 1);

-- error: pos > length
SELECT utl_raw.substr('\x616263'::raw, 4, 1);

-- error: pos < -length
SELECT utl_raw.substr('\x616263'::raw, -4, 1);

-- error: len = 0
SELECT utl_raw.substr('\x616263'::raw, 1, 0);

-- error: len < 0
SELECT utl_raw.substr('\x616263'::raw, 1, -1);

-- error: empty input
SELECT utl_raw.substr('\x'::raw, 1);

-- ============================================================
-- utl_raw.concat(VARIADIC raw[]) → raw
-- ============================================================

-- single argument
SELECT utl_raw.concat('\x616263'::raw);

-- two arguments
SELECT utl_raw.concat('\x61'::raw, '\x62'::raw);

-- three arguments
SELECT utl_raw.concat('\x61'::raw, '\x62'::raw, '\x63'::raw);

-- five arguments
SELECT utl_raw.concat('\x61'::raw, '\x62'::raw, '\x63'::raw, '\x64'::raw, '\x65'::raw);

-- empty element is kept (zero bytes, not NULL)
SELECT utl_raw.concat('\x61'::raw, '\x'::raw, '\x63'::raw);

-- NULL element is skipped (Oracle behavior)
SELECT utl_raw.concat('\x61'::raw, NULL::raw, '\x63'::raw);

-- leading NULL skipped
SELECT utl_raw.concat(NULL::raw, '\x62'::raw, '\x63'::raw);

-- trailing NULL skipped
SELECT utl_raw.concat('\x61'::raw, '\x62'::raw, NULL::raw);

-- all-NULL arguments → empty raw
SELECT utl_raw.concat(NULL::raw, NULL::raw, NULL::raw);

-- concat results of cast_to_raw
SELECT utl_raw.concat(
    utl_raw.cast_to_raw('foo'),
    utl_raw.cast_to_raw('bar')
);

-- concat single-byte values to form a known word
SELECT utl_raw.cast_to_varchar2(
    utl_raw.concat('\x48'::raw, '\x65'::raw, '\x6c'::raw, '\x6c'::raw, '\x6f'::raw)
);

-- ============================================================
-- utl_raw.convert(raw, to_charset, from_charset) → raw
-- ============================================================

-- same encoding: no-op (ASCII is identical in all common encodings)
SELECT utl_raw.convert('\x616263'::raw, 'UTF8', 'UTF8');

-- Oracle-style source name: AL32UTF8 maps to UTF8
SELECT utl_raw.convert('\x616263'::raw, 'UTF8', 'AL32UTF8');

-- Oracle-style target name: ZHS16GBK maps to GBK
-- 你 = U+4F60, UTF-8 = E4 BD A0, GBK = C4 E3
SELECT utl_raw.convert('\xe4bda0'::raw, 'ZHS16GBK', 'UTF8');

-- charset names are case-insensitive
SELECT utl_raw.convert('\x616263'::raw, 'utf8', 'UTF8');

-- empty input → empty output
SELECT utl_raw.convert('\x'::raw, 'UTF8', 'UTF8');

-- NULL → NULL (STRICT)
SELECT utl_raw.convert(NULL::raw, 'UTF8', 'UTF8');

-- UTF-8 → GBK: 你 (U+4F60, \xe4bda0) → GBK C4 E3 (\xc4e3)
SELECT utl_raw.convert('\xe4bda0'::raw, 'GBK', 'UTF8');

-- GBK → UTF-8: round-trip verification
SELECT utl_raw.convert('\xc4e3'::raw, 'UTF8', 'GBK');

-- round-trip: UTF8 → GBK → UTF8 returns the original bytes
SELECT utl_raw.convert(
    utl_raw.convert('\xe4bda0'::raw, 'GBK', 'UTF8'),
    'UTF8', 'GBK'
) = '\xe4bda0'::raw;

-- UTF-8 → GBK: 你好 (U+4F60 U+597D)
-- 你 = E4 BD A0 → C4 E3
-- 好 = E5 A5 BD → BA C3
SELECT utl_raw.convert('\xe4bda0e5a5bd'::raw, 'GBK', 'UTF8');

-- error: invalid from_charset
SELECT utl_raw.convert('\x616263'::raw, 'UTF8', 'NOSUCHENCODING');

-- error: invalid to_charset
SELECT utl_raw.convert('\x616263'::raw, 'NOSUCHENCODING', 'UTF8');

-- ============================================================
-- Cleanup
-- ============================================================

DROP EXTENSION orafce_ext;
DROP EXTENSION orafce CASCADE;
