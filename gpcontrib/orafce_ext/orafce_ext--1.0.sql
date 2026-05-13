/* orafce_ext--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION orafce_ext" to load this file. \quit

-- ---------------------------------------------------------------------------
-- RAW type
--
-- Oracle's RAW is a variable-length binary string.  We model it as a domain
-- over bytea so that all bytea operators and functions apply automatically.
-- ---------------------------------------------------------------------------

CREATE DOMAIN oracle.raw AS bytea;

-- ---------------------------------------------------------------------------
-- UTL_RAW schema
-- ---------------------------------------------------------------------------

CREATE SCHEMA utl_raw;

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_raw
--
-- Converts a VARCHAR2 value to RAW by reinterpreting its byte sequence
-- without any character-set conversion.
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.cast_to_raw(c oracle.varchar2)
RETURNS oracle.raw
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_cast_to_raw';

COMMENT ON FUNCTION utl_raw.cast_to_raw(oracle.varchar2)
IS 'Convert VARCHAR2 to RAW by reinterpreting its bytes';

-- ---------------------------------------------------------------------------
-- utl_raw.cast_to_varchar2
--
-- Converts a RAW value to VARCHAR2 by reinterpreting its byte sequence
-- without any character-set conversion.
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.cast_to_varchar2(r oracle.raw)
RETURNS oracle.varchar2
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_cast_to_varchar2';

COMMENT ON FUNCTION utl_raw.cast_to_varchar2(oracle.raw)
IS 'Convert RAW to VARCHAR2 by reinterpreting its bytes';

-- ---------------------------------------------------------------------------
-- utl_raw.length
--
-- Returns the length of a RAW value in bytes.
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.length(r oracle.raw)
RETURNS integer
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_length';

COMMENT ON FUNCTION utl_raw.length(oracle.raw)
IS 'Return the byte length of a RAW value';

-- ---------------------------------------------------------------------------
-- utl_raw.substr
--
-- Returns a substring of a RAW value.
--
-- Oracle semantics:
--   pos  - 1-based start position; negative counts backward from end
--   len  - number of bytes to return; omit or NULL to return to end
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.substr(r oracle.raw, pos integer, len integer DEFAULT NULL)
RETURNS oracle.raw
LANGUAGE c PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_substr';

COMMENT ON FUNCTION utl_raw.substr(oracle.raw, integer, integer)
IS 'Return a substring of a RAW value (Oracle-compatible semantics)';

-- ---------------------------------------------------------------------------
-- utl_raw.concat
--
-- Concatenates up to 12 RAW values into a single RAW value.
-- NULL arguments are silently ignored.
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.concat(VARIADIC raws oracle.raw[])
RETURNS oracle.raw
LANGUAGE c STRICT IMMUTABLE PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_concat';

COMMENT ON FUNCTION utl_raw.concat(VARIADIC oracle.raw[])
IS 'Concatenate multiple RAW values, ignoring NULLs';

-- ---------------------------------------------------------------------------
-- utl_raw.convert
--
-- Converts RAW data from one character set to another.
-- Accepts both Oracle-style names (AL32UTF8, ZHS16GBK) and
-- PostgreSQL/iconv-style names (UTF8, GBK).
-- ---------------------------------------------------------------------------

CREATE FUNCTION utl_raw.convert(r oracle.raw, to_charset text, from_charset text)
RETURNS oracle.raw
LANGUAGE c STRICT PARALLEL SAFE
AS '$libdir/orafce_ext', 'utl_raw_convert';

COMMENT ON FUNCTION utl_raw.convert(oracle.raw, text, text)
IS 'Convert RAW data between character sets';
