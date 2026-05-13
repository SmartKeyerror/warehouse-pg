MODULE_big = orafce_ext
OBJS = utl_raw.o

EXTENSION = orafce_ext
DATA = orafce_ext--1.0.sql

REGRESS = utl_raw
REGRESS_OPTS = --encoding=utf8

PG_CONFIG ?= pg_config

ifdef NO_PGXS
subdir = gpcontrib/orafce_ext
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
else
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
endif
