.PHONY: all clean

UNAME_M=$(shell uname -m)

all:
	docker build .

clean:
