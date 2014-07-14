sass: $(shell find sass -iname '*.sass')

.PHONY: all clean-css deps

all: public/css

public/css: $(sass)
	compass compile -s nested --sass-dir sass --css-dir $@
	touch $@

clean: clean-css

clean-css:
	rm -rf .sass-cache public/css/*

deps:
	bundle install
	rbenv rehash
