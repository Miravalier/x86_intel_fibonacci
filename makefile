ASFLAGS = -W

all: fibonacci

clean:
	$(RM) fibonacci

fibonacci: fibonacci.s

.PHONY: all clean
