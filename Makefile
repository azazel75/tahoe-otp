#-*- coding: utf-8 -*-
#:Progetto:  PassionHub -- Main makefile
#:Creato:    ven 16 ago 2013 22:48:32 CEST
#:Autore:    Lele Gaifax <lele@metapensiero.it>
#:Licenza:   GNU General Public License version 3 or later
#

export TOPDIR := $(CURDIR)
export FLAVOR = development
export SHELL := /bin/bash
export VENVDIR := $(TOPDIR)/env
export PYTHON := $(VENVDIR)/bin/python
export SYS_PYTHON := /usr/bin/python2.7

VENV_VER = 1.10.1
VENV_SETUP := https://pypi.python.org/packages/source/v/virtualenv/virtualenv-$(VENV_VER).tar.gz
SETUPTOOLS_PTH := $(VENVDIR)/lib/python2.7/site-packages/setuptools.pth
SETUPTOOLS_SETUP := https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py
PIP := $(VENVDIR)/bin/pip
PIP_SETUP := https://raw.github.com/pypa/pip/master/contrib/get-pip.py
REQUIREMENTS_TIMESTAMP := $(VENVDIR)/requirements.timestamp
WGET := wget --quiet --no-check-certificate


# This is the default target, when no target is specified on the command line
.PHONY: all
all: virtualenv buildout

# Cleanup
.PHONY: clean
clean::

# Cleanup even more
.PHONY: realclean
realclean:: clean

# Remove anything downloadable/rebuildable
.PHONY: distclean
distclean:: realclean


## virtual env rules

.PHONY: virtualenv
virtualenv: $(VENVDIR) $(PIP) requirements

$(VENVDIR):
	@echo "Bootstrapping Python 2.7 virtualenv..."
	@$(WGET) $(VENV_SETUP) -O venv.tgz
	@tar -xzf venv.tgz
	@-cd virtualenv-$(VENV_VER) && $(SYS_PYTHON) virtualenv.py ../env
	@-rm -rf $(TOPDIR)/virtualenv-* $(TOPDIR)/venv.tgz

$(SETUPTOOLS_PTH):
	@echo "Installing setuptools..."
	@$(WGET) $(SETUPTOOLS_SETUP) -O - | $(PYTHON) > /dev/null 2>&1
	@-rm -f $(TOPDIR)/setuptools-*.tar.gz

$(PIP):
	@echo "Installing pip..."
	@$(WGET) $(PIP_SETUP) -O - | $(PYTHON) > /dev/null

.PHONY: requirements
requirements: $(REQUIREMENTS_TIMESTAMP)

$(REQUIREMENTS_TIMESTAMP): requirements.txt
	@echo "Installing pre-requirements..."
	@PATH=$(TOPDIR)/bin:$(PATH) $(PIP) install -r requirements.txt | grep --line-buffered -v '^   '
	@touch $@

distclean::
	rm -rf $(REQUIREMENTS_TIMESTAMP)
	rm -rf $(TOPDIR)/bin $(TOPDIR)/lib $(TOPDIR)/include


## buildout rules

BUILDOUT := $(TOPDIR)/bin/buildout
BODIR := $(TOPDIR)/buildout
BOCFGS := $(wildcard $(BODIR)/*.cfg)
BOTSTAMP := $(BODIR)/timestamp
BOMAIN := $(BODIR)/$(FLAVOR).cfg
BOCACHE := $(HOME)/.buildout/dlcache
BOPARTS := $(BODIR)/parts
BOSTATUS := $(BODIR)/status
BOFLAGS := -c $(BOMAIN) \
	   buildout:directory=$(TOPDIR) \
	   buildout:parts-directory=$(BOPARTS) \
	   buildout:download-cache=$(BOCACHE) \
	   buildout:installed=$(BOSTATUS) \
	   buildout:confdir=$(BODIR) \
	   buildout:vardir=$(TOPDIR)/var

.PHONY: buildout
buildout: $(BUILDOUT) $(BOTSTAMP)

$(BUILDOUT): bootstrap.py
	@mkdir -p $(TOPDIR)/var
	@mkdir -p $(BOCACHE)
	@echo "Bootstrapping buildout..."
	@$(PYTHON) bootstrap.py $(BOFLAGS)
	@touch $(BUILDOUT)

#$(BOTSTAMP): $(SERVERDIR)/setup.py
$(BOTSTAMP): $(BOCFGS)
	@echo "Executing buildout..."
	@$(BUILDOUT) $(BOFLAGS)
	@touch $(BOTSTAMP)

clean::
	rm -f $(BOTSTAMP)

realclean::
	rm -f $(BOSTATUS)

distclean::
	rm -rf $(BOPARTS) $(TOPDIR)/develop-eggs

include Makefile.$(FLAVOR)
