# Makefile for apilib (apilib/)
# Builds on Ubuntu using nasm -f elf32 + ar.

NASM      = nasm
AR        = ar
DEL       = rm -f

BUILD     = ../build/
NASMFLAGS = -f elf32

OBJS_API = apilib.o

default: apilib.a

apilib.a: $(OBJS_API) Makefile
	$(AR) rcs $@ $(OBJS_API)

%.o: %.nas Makefile
	$(NASM) $(NASMFLAGS) $< -o $@

clean:
	-$(DEL) *.o *.a *.lst

src_only:
	$(MAKE) clean
