-- utl_raw regression tests

CREATE EXTENSION orafce;
CREATE EXTENSION orafce_ext;

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_raw
-- ---------------------------------------------------------------------------

SELECT utl_raw.cast_to_raw('abc');
SELECT utl_raw.cast_to_raw('');
SELECT utl_raw.cast_to_raw(NULL);

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_varchar2
-- ---------------------------------------------------------------------------

SELECT utl_raw.cast_to_varchar2(utl_raw.cast_to_raw('hello'));
SELECT utl_raw.cast_to_varchar2('\x616263'::raw);
SELECT utl_raw.cast_to_varchar2(NULL::raw);

-- ---------------------------------------------------------------------------
-- utl_raw.length
-- ---------------------------------------------------------------------------

SELECT utl_raw.length('\x616263'::raw);    -- 3
SELECT utl_raw.length('\x00'::raw);         -- 1
SELECT utl_raw.length('\x'::raw);           -- 0
SELECT utl_raw.length(NULL::raw);           -- NULL

-- ---------------------------------------------------------------------------
-- utl_raw.substr
-- ---------------------------------------------------------------------------

SELECT utl_raw.substr('\x616263'::raw, 1, 2);   -- \x6162
SELECT utl_raw.substr('\x616263'::raw, 1);       -- \x616263 (to end)
SELECT utl_raw.substr('\x616263'::raw, 2);       -- \x6263
SELECT utl_raw.substr('\x616263'::raw, -1, 1);   -- \x63 (last byte)
SELECT utl_raw.substr('\x616263'::raw, -2, 2);   -- \x6263

-- error cases
SELECT utl_raw.substr('\x616263'::raw, 0, 1);    -- pos=0 is invalid
SELECT utl_raw.substr('\x616263'::raw, 4, 1);    -- pos out of range
SELECT utl_raw.substr('\x616263'::raw, 1, 0);    -- len<1 is invalid

-- ---------------------------------------------------------------------------
-- utl_raw.concat
-- ---------------------------------------------------------------------------

SELECT utl_raw.concat('\x61'::raw, '\x62'::raw, '\x63'::raw);  -- \x616263
SELECT utl_raw.concat('\x616263'::raw);                          -- single value
SELECT utl_raw.concat('\x61'::raw, NULL::raw, '\x63'::raw);     -- NULL skipped
SELECT utl_raw.concat(
    utl_raw.cast_to_raw('foo'),
    utl_raw.cast_to_raw('bar')
);

-- ---------------------------------------------------------------------------
-- utl_raw.convert
-- ---------------------------------------------------------------------------

SELECT utl_raw.convert('\x616263'::raw, 'UTF8', 'UTF8');        -- no-op
SELECT utl_raw.convert('\x616263'::raw, 'UTF8', 'AL32UTF8');    -- Oracle name
SELECT utl_raw.convert('\x616263'::raw, 'NOSUCHENC', 'UTF8');   -- error

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------

DROP EXTENSION orafce_ext;
DROP EXTENSION orafce CASCADE;
