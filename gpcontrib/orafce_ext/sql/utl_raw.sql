-- utl_raw regression tests
-- Requires orafce to be installed first (for oracle.varchar2 type)

CREATE EXTENSION orafce;
CREATE EXTENSION orafce_ext;

SET search_path = utl_raw, oracle, public;

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_raw
-- ---------------------------------------------------------------------------

-- Basic ASCII string
SELECT utl_raw.cast_to_raw('abc'::oracle.varchar2);

-- Empty string
SELECT utl_raw.cast_to_raw(''::oracle.varchar2);

-- NULL input returns NULL (STRICT function)
SELECT utl_raw.cast_to_raw(NULL::oracle.varchar2);

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_varchar2
-- ---------------------------------------------------------------------------

-- Round-trip: cast to raw then back
SELECT utl_raw.cast_to_varchar2(utl_raw.cast_to_raw('hello'::oracle.varchar2));

-- Direct bytea input
SELECT utl_raw.cast_to_varchar2('\x616263'::oracle.raw);

-- NULL input returns NULL
SELECT utl_raw.cast_to_varchar2(NULL::oracle.raw);

-- ---------------------------------------------------------------------------
-- utl_raw.length
-- ---------------------------------------------------------------------------

SELECT utl_raw.length('\x616263'::oracle.raw);       -- 3 bytes
SELECT utl_raw.length('\x00'::oracle.raw);            -- 1 byte (null byte)
SELECT utl_raw.length('\x'::oracle.raw);              -- 0 bytes (empty)
SELECT utl_raw.length(NULL::oracle.raw);              -- NULL

-- ---------------------------------------------------------------------------
-- utl_raw.substr
-- ---------------------------------------------------------------------------

-- Basic: first two bytes
SELECT utl_raw.substr('\x616263'::oracle.raw, 1, 2);

-- To end of value (no len)
SELECT utl_raw.substr('\x616263'::oracle.raw, 1);

-- Start from second byte
SELECT utl_raw.substr('\x616263'::oracle.raw, 2);

-- Last byte using negative pos
SELECT utl_raw.substr('\x616263'::oracle.raw, -1, 1);

-- Two bytes from the end
SELECT utl_raw.substr('\x616263'::oracle.raw, -2, 2);

-- pos = 0 raises error
SELECT utl_raw.substr('\x616263'::oracle.raw, 0, 1);

-- pos out of range raises error
SELECT utl_raw.substr('\x616263'::oracle.raw, 4, 1);

-- len < 1 raises error
SELECT utl_raw.substr('\x616263'::oracle.raw, 1, 0);

-- ---------------------------------------------------------------------------
-- utl_raw.concat
-- ---------------------------------------------------------------------------

-- Three values
SELECT utl_raw.concat('\x61'::oracle.raw, '\x62'::oracle.raw, '\x63'::oracle.raw);

-- Single value
SELECT utl_raw.concat('\x616263'::oracle.raw);

-- NULL arguments are skipped
SELECT utl_raw.concat('\x61'::oracle.raw, NULL::oracle.raw, '\x63'::oracle.raw);

-- Round-trip through cast_to_raw
SELECT utl_raw.concat(
    utl_raw.cast_to_raw('foo'::oracle.varchar2),
    utl_raw.cast_to_raw('bar'::oracle.varchar2)
);

-- ---------------------------------------------------------------------------
-- utl_raw.convert (charset conversion)
-- ---------------------------------------------------------------------------

-- UTF-8 to GBK using PG-style names (passthrough)
SELECT utl_raw.convert(utl_raw.cast_to_raw('hello'::oracle.varchar2), 'UTF8', 'UTF8');

-- Same encoding: no-op
SELECT utl_raw.convert('\x616263'::oracle.raw, 'UTF8', 'UTF8');

-- Oracle-style source name
SELECT utl_raw.convert('\x616263'::oracle.raw, 'UTF8', 'AL32UTF8');

-- Invalid charset raises error
SELECT utl_raw.convert('\x616263'::oracle.raw, 'NOSUCHENCODING', 'UTF8');

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------

DROP EXTENSION orafce_ext;
DROP EXTENSION orafce;
