######################################################
# File:                  Makefile                    #
# App Name:              grid-to-climdivs            #
# Functionality:         Installation and Setup      #
# Author:                Adam Allgood                #
# Date Makefile created: 2018-09-20                  #
######################################################

# --- Rules ---

.PHONY: permissions
.PHONY: dirs

# --- make install ---

install: permissions dirs

# --- permissions ---

permissions:
	chmod 755 ./drivers/*
	chmod 755 ./scripts/*

# --- dirs ---

dirs:
	mkdir -p ./logs
	mkdir -p ./work
