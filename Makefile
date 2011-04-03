# Build recipe for lpath.
#
# Copyright (C) 2011 Gary V. Vaughan
#
# License: MIT open source license <http://www.lua.org/license.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

INSTALL = install
LUA = $(LUABIN)/lua
MKDIR_P = $(INSTALL) -c -d
RM = rm
RMDIR = rmdir
TAR = tar

srcdir = .
top_srcdir = .
builddir = .
top_builddir = .

# 1. USER OVERRIDEABLE VARIABLES
# ==============================
# Macros you might want to change, or override when you invoke make.

CFLAGS = -O2

LUAVERSION = 5.1
LUAPREFIX = /usr/local
LUABIN = $(LUAPREFIX)/bin
LUAINC = $(LUAPREFIX)/include

prefix = $(LUAPREFIX)
datadir = $(prefix)/share

pkglibdir = $(prefix)/lib/lua/$(LUAVERSION)
pkgdatadir = $(datadir)/lua/$(LUAVERSION)


# 2. LPATH BUILD DEFINITIONS
# ==========================
# These declarations specialize the build rules in the following
# section to build this package.

PACKAGE_NAME = lpath
PACKAGE_MICRO_VERSION =	0

GIT_REV := $(shell test -d .git && git describe --always)
ifeq ($(GIT_REV),)
  PACKAGE_VERSION := $(LUAVERSION).$(PACKAGE_MICRO_VERSION)
else
  PACKAGE_VERSION := $(GIT_REV)
endif

AM_CPPFLAGS = -I$(LUAINC) -DPATH_VERSION=\"$(PACKAGE_MICRO_VERSION)\"

pkglib_MODULES = path.so
path_so_SOURCES = lpathlib.c
path_so_OBJECTS = $(path_so_SOURCES:.c=.o)

pkgdata_DATA = lpath.lua

TESTS = test.lua

MODULES = $(pkglib_MODULES)
LIBOBJECTS = $(path_so_OBJECTS)
DIST_SOURCES = $(path_so_SOURCES) $(pkgdata_DATA) $(TESTS)


# 3. GENERIC BUILD RULES
# ======================
# Non specialized build rules for compiling targets.

ifeq ($(shell uname),Darwin)
  MODULES_LDFLAGS = -bundle -undefined dynamic_lookup
else
  MODULES_LDFLAGS = -shared
endif

MODULES_COMPILE = $(CC) $(CPPFLAGS) $(AM_CPPFLAGS) $(CFLAGS) $(AM_CFLAGS) -fpic
MODULES_LINK = $(CC) $(CFLAGS) -fpic $(LDFLAGS) $(AM_LDFLAGS)

all: $(MODULES)

$(LIBOBJECTS): $(LIBOBJECTS:.o=.c)
ifneq (,$(findstring s,$(MAKEFLAGS)))
	@echo CC $^
else
	@echo $(MODULES_COMPILE) -c -o $@ $^
endif
	@$(MODULES_COMPILE) -c -o $@ $^

$(MODULES): $(LIBOBJECTS)
ifneq (,$(findstring s,$(MAKEFLAGS)))
	@echo LD $@
else
	@echo $(MODULES_LINK) $(MODULES_LDFLAGS) $(LIBOBJECTS) -o $@ $(LIBS)
endif
	@$(MODULES_LINK) $(MODULES_LDFLAGS) $(LIBOBJECTS) -o $@ $(LIBS)

check: all
	@for t in $(TESTS); do \
		$(LUA) $$t; \
	done

clean:
	rm -f $(LIBOBJECTS) $(MODULES) core core.* a.out

install: $(MODULES)
	test -d $(DESTDIR)$(pkglibdir) || $(MKDIR_P) $(DESTDIR)$(pkglibdir)
	@for l in $(MODULES); do \
	  echo $(INSTALL) $$l $(DESTDIR)$(pkglibdir)/$$l; \
	  $(INSTALL) $$l $(DESTDIR)$(pkglibdir)/$$l; \
	done
	test -d $(DESTDIR)$(pkgdatadir) || $(MKDIR_P) $(DESTDIR)$(pkgdatadir)
	@for l in $(pkgdata_DATA); do \
	  echo $(INSTALL) -m 644 $$l $(DESTDIR)$(pkgdatadir)/$$l; \
	  $(INSTALL) -m 644 $$l $(DESTDIR)$(pkgdatadir)/$$l; \
	done

uninstall:
	@for l in $(MODULES); do \
	  echo $(RM) -f $(DESTDIR)$(pkglibdir)/$$l; \
	  $(RM) -f $(DESTDIR)$(pkglibdir)/$$l; \
	done
	$(RMDIR) $(DESTDIR)$(pkglibdir) || :
	@for l in $(pkgdata_DATA); do \
	  echo $(RM) -f $(DESTDIR)$(pkgdatadir)/$$l; \
	  $(RM) -f $(DESTDIR)$(pkgdatadir)/$$l; \
	done
	$(RMDIR) $(DESTDIR)$(pkgdatadir) || :

DIST_COMMON = README $(srcdir)/Makefile
DISTFILES = $(DIST_COMMON) $(DIST_SOURCES) $(EXTRA_DIST)
distdir = $(PACKAGE_NAME)-$(PACKAGE_MICRO_VERSION)
top_distdir = $(distdir)

am__remove_distdir = \
  { test ! -d $(distdir) \
    || { find $(distdir) -type d ! -perm -200 -exec chmod u+w {} ';' \
         && rm -fr $(distdir); }; }
GZIP_ENV = --best
distdir: $(DISTFILES)
	$(am__remove_distdir)
	test -d $(distdir) || mkdir $(distdir)
	@srcdirstrip=`echo "$(srcdir)" | sed 's/[].[^$$\\*]/\\\\&/g'`; \
	topsrcdirstrip=`echo "$(top_srcdir)" | sed 's/[].[^$$\\*]/\\\\&/g'`; \
	list='$(DISTFILES)'; \
		dist_files=`for file in $$list; do echo $$file; done | \
		sed -e "s|^$$srcdirstrip/||;t" \
				-e "s|^$$topsrcdirstrip/|$(top_builddir)/|;t"`; \
	case $$dist_files in \
		*/*) $(MKDIR_P) `echo "$$dist_files" | \
				 sed '/\//!d;s|^|$(distdir)/|;s,/[^/]*$$,,' | \
				 sort -u` ;; \
	esac; \
	for file in $$dist_files; do \
	  if test -f $$file || test -d $$file; then d=.; else d=$(srcdir); fi; \
	  if test -d $$d/$$file; then \
	    dir=`echo "/$$file" | sed -e 's,/[^/]*$$,,'`; \
	    if test -d $(srcdir)/$$file && test $$d != $(srcdir); then \
	      cp -pR $(srcdir)/$$file $(distdir)$$dir || exit 1; \
	    fi; \
	    cp -pR $$d/$$file $(distdir)$$dir || exit 1; \
	  else \
	    test -f $(distdir)/$$file \
	    || cp -p $$d/$$file $(distdir)/$$file \
	    || exit 1; \
	  fi; \
	done
	-find $(distdir) -type d ! -perm -777 -exec chmod a+rwx {} \; -o \
	  ! -type d ! -perm -444 -links 1 -exec chmod a+r {} \; -o \
	  ! -type d ! -perm -400 -exec chmod a+r {} \; -o \
	  ! -type d ! -perm -444 -exec $(INSTALL) -c -m a+r {} {} \; \
	|| chmod -R a+r $(distdir)

am__tar = ${TAR} chof - "$$tardir"

dist: distdir
	tardir=$(distdir) && $(am__tar) | GZIP=$(GZIP_ENV) gzip -c >$(distdir).tar.gz
	$(am__remove_distdir)
