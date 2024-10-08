.PHONY: all clean

UNAME_M=$(shell uname -m)
CLANG_BUILD_VER_MAJ=18
CLANG_BUILD_VER=$(CLANG_BUILD_VER_MAJ).1.7

all:
	docker build --build-arg VER_MAJ=$(CLANG_BUILD_VER_MAJ) --build-arg VER=$(CLANG_BUILD_VER) \
		optee_build_git/clang -f optee_build_git/clang/Dockerfile -t optee_os_ci_clang_builder
	docker build --build-arg CLANG_BUILD_VER=$(CLANG_BUILD_VER) .

clean:
	docker image rm optee_os_ci-clang_builder
