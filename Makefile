sass: $(shell find sass -iname '*.sass')

coffee: $(shell find coffee -iname '*.coffee')

.PHONY: all clean-css deps

all: public/css public/scripts

public/scripts: $(coffee)
	coffee -o public/scripts/ -c coffee

public/css: $(sass)
	compass compile -s nested --sass-dir sass --css-dir $@
	touch $@

clean: clean-css clean-js

clean-css:
	rm -r .sass-cache public/css/*

clean-js:
	rm -r public/scripts/*

deps:
	bundle install
	rbenv rehash
