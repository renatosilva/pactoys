system_version := $(shell uname -r | cut --delimiter=. --fields=1)
system_type    := $(shell uname -o)$(system_version)

all:
	$(MAKE) -C source/repman/native

clean:
	$(MAKE) -C source/repman/native clean

install:

# Main programs
	install -Dm755 source/makepatch/makepatch.sh           "$(DESTDIR)/usr/bin/makepatch"
	install -Dm755 source/repman/native/repman             "$(DESTDIR)/usr/bin/repman"
	install -Dm755 source/saneman/saneman.sh               "$(DESTDIR)/usr/bin/saneman"
	install -Dm755 source/updpkgver/updpkgver.sh           "$(DESTDIR)/usr/bin/updpkgver"
	install -Dm644 source/saneman/modules/default.sane.sh  "$(DESTDIR)/usr/share/saneman/modules/default.sane"

# Library
	install -Dm644 library/pactoys.sh                      "$(DESTDIR)/usr/bin/pactoys"
	install -Dm644 library/default.sh                      "$(DESTDIR)/usr/share/pactoys/library/default.sh"
	install -Dm644 library/output.sh                       "$(DESTDIR)/usr/share/pactoys/library/output.sh"
	install -Dm644 library/recipe.sh                       "$(DESTDIR)/usr/share/pactoys/library/recipe.sh"
	install -Dm644 library/util.sh                         "$(DESTDIR)/usr/share/pactoys/library/util.sh"

# Licenses
	install -Dm644 LICENSE                                 "$(DESTDIR)/usr/share/licenses/pactoys/LICENSE"
	install -Dm644 source/repman/native/inih/LICENSE.txt   "$(DESTDIR)/usr/share/licenses/pactoys/inih/LICENSE"

# MSYS2
ifeq ($(system_type),Msys2)
	mkdir -p "$(DESTDIR)/var/cache/pacboy"
	install -Dm755 source/pacboy/pacboy.sh                 "$(DESTDIR)/usr/bin/pacboy"
	install -Dm644 source/pacboy/pacboy.completion         "$(DESTDIR)/usr/share/bash-completion/completions/pacboy"
	install -Dm644 source/saneman/modules/msys2.sane.sh    "$(DESTDIR)/usr/share/saneman/modules/msys2.sane"
endif
