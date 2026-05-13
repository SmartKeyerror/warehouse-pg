/* orafce_ext--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION orafce_ext" to load this file. \quit

SET search_path = oracle, public;

-- ---------------------------------------------------------------------------
-- RAW type
--
-- Oracle's RAW is a variable-length binary string.  We define it as a domain
-- over bytea in the public schema so it is accessible without needing to
-- add "oracle" to search_path.
-- ---------------------------------------------------------------------------

CREATE DOMAIN raw AS bytea;

-- ---------------------------------------------------------------------------
-- UTL_RAW schema
-- ---------------------------------------------------------------------------

CREATE SCHEMA utl_raw;

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_raw
--
-- Converts a character string to RAW by reinterpreting its byte sequence
-- without any character-set conversion.
--
-- Accepts text, which is compatible with oracle.varchar2 via orafce's
-- implicit cast, so both of these work:
--   utl_raw.cast_to_raw('abc')
--   utl_raw.cast_to_raw('abc'::varchar2)   -- requires oracle in search_path
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.cast_to_raw(c text)
RETURNS raw
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_cast_to_raw';

COMMENT ON FUNCTION utl_raw.cast_to_raw(text)
IS 'Convert a string to RAW by reinterpreting its bytes';

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_varchar2
--
-- Converts a RAW value to text by reinterpreting its byte sequence without
-- any character-set conversion.
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.cast_to_varchar2(r raw)
RETURNS text
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_cast_to_varchar2';

COMMENT ON FUNCTION utl_raw.cast_to_varchar2(raw)
IS 'Convert RAW to text by reinterpreting its bytes';

-- ---------------------------------------------------------------------------
-- utl_raw.length
--
-- Returns the length of a RAW value in bytes.
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.length(r raw)
RETURNS integer
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_length';

COMMENT ON FUNCTION utl_raw.length(raw)
IS 'Return the byte length of a RAW value';

-- ---------------------------------------------------------------------------
-- utl_raw.substr
--
-- Returns a substring of a RAW value.
--
-- Oracle semantics:
--   pos  - 1-based start position; negative values count backward from end
--   len  - number of bytes to return; omit or NULL means "to the end"
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.substr(r raw, pos integer, len integer DEFAULT NULL)
RETURNS raw
LANGUAGE c PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_substr';

COMMENT ON FUNCTION utl_raw.substr(raw, integer, integer)
IS 'Return a substring of a RAW value (Oracle-compatible semantics)';

-- ---------------------------------------------------------------------------
-- utl_raw.concat
--
-- Concatenates multiple RAW values into a single RAW value.
-- NULL arguments are silently ignored (Oracle behavior).
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.concat(VARIADIC raws raw[])
RETURNS raw
LANGUAGE c IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_concat';

COMMENT ON FUNCTION utl_raw.concat(VARIADIC raw[])
IS 'Concatenate multiple RAW values, ignoring NULLs';

-- ---------------------------------------------------------------------------
-- utl_raw.convert
--
-- Converts RAW data from one character set to another.
-- Accepts both Oracle-style names (AL32UTF8, ZHS16GBK) and
-- PostgreSQL/iconv-style names (UTF8, GBK).
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.convert(r raw, to_charset text, from_charset text)
RETURNS raw
LANGUAGE c STRICT PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_convert';

COMMENT ON FUNCTION utl_raw.convert(raw, text, text)
IS 'Convert RAW data between character sets';
