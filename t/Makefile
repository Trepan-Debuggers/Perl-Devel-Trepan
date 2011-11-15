#: Whatever it is you want to do, it should be handled by the main
# (parent) Makefile. So reissue make from there.
.PHONY: all

#: Whatever it is you want to do, it should be handled by the parent
all:
	$(MAKE) -C .. -f GNUmakefile check

%:
	$(MAKE) -C .. -f GNUmakefile $@
