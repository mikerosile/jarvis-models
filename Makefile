MODELS := $(patsubst %/,%,$(dir $(wildcard */model.url)))

.PHONY: all clean
all: $(addsuffix /model.gguf,$(MODELS))

%/model.gguf:
	@url=$$(tr -d ' \t\r\n' < $(@D)/model.url); \
	name=$${url##*/}; \
	echo ">>> [$(basename $@)] hf download $$url --local-dir $(@D)"; \
	hf download $$url --local-dir $(@D); \
	if [ -f "$(@D)/$$name" ]; then mv "$(@D)/$$name" $(@D)/model.gguf; echo ">>> [$(basename $@)] saved as model.gguf"; fi

clean:
	rm -f $(addsuffix /model.gguf,$(MODELS))
