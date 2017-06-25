ifeq ($(shell which erl),)
$(error Can't find Erlang executable 'erl')
exit 1
endif

#########################################
# Common Variables
#########################################
ESCRIPT=$(shell which escript)
IPY_KERN=$(shell pwd)/bin/start_kernel
DEP_LIBS1=$(shell pwd)/deps/erlzmq:$(shell pwd)/deps/mochiweb
DEP_LIBS=$(DEP_LIBS1):$(shell pwd)/deps/sandbox:$(shell pwd)/deps/uuid
IERLANG_LIB=$(shell pwd)
ERLLIBS=$(ERL_LIBS):$(DEP_LIBS):$(IERLANG_LIB)
IERLANG_DEMO=notebooks/ierlang_demo.ipynb
OPT_KERN_MGR_CMD='["$(ESCRIPT)", "$(IPY_KERN)", "{connection_file}"]'

erl:
	ERL_LIBS=$(ERLLIBS) erl

erlclean:
	rebar clean

clean: pyclean py3clean erlclean

compile:
	@echo "Compiling IErlang..."
	@rebar get-deps
	@rebar compile


#########################################
# Python 2.7 Specific
#########################################
PY2=python2.7
PY2_VENV=./.venv-py2
PY2_VENV_BIN=$(PY2_VENV)/bin/$(PY2)
PATCHED=patches/patched
SESSION_SRC=$(PY2_VENV)/lib/python2.7/site-packages/IPython/kernel/zmq/session.py

$(PY2_VENV_BIN):
	@virtualenv --python=$(PY2) $(PY2_VENV)

py2deps: $(PY2_VENV_BIN)
	@. $(PY2_VENV)/bin/activate && \
	pip install -r requirements.txt
	@make $(PATCHED)

$(PATCHED):
	patch $(SESSION_SRC) < patches/ierlang.patch
	touch $(PATCHED)

py2shell-base:
	@echo "Starting IErlang Console..."
	. $(PY2_VENV)/bin/activate && \
	ERL_LIBS=$(ERLLIBS) \
	ipython2 console \
	--KernelManager.kernel_cmd=$(OPT_KERN_MGR_CMD) \
	--Session.key="" \
	--Session.keyfile=""

py2shell-no-deps:
	@rebar compile skip_deps=true
	@make py2shell-base

py2shell: py2deps compile py2shell-base

pyclean:
	rm -rf $(PY2_VENV) $(PATCHED)

demo-base:
	@echo "Starting IErlang Notebook Demo..."
	@. $(PY2_VENV)/bin/activate && \
	ERL_LIBS=$(ERLLIBS) \
	ipython2 notebook $(IERLANG_DEMO) \
	--KernelManager.kernel_cmd=$(OPT_KERN_MGR_CMD) \
	--Session.key="" \
	--Session.keyfile=""

demo: py2deps compile demo-base

demo-no-deps:
	@rebar compile skip_deps=true
	@make demo-base

py2notebook: IERLANG_DEMO=notebooks
py2notebook: py2deps compile demo-base




#########################################
# Python 3.4 Specific
#########################################
PY3=python3.4
PY3_VENV=./.venv-py3
PY3_VENV_BIN=$(PY3_VENV)/bin/$(PY3)
SESSION_SRC3=$(PY3_VENV)/lib/$(PY3)/site-packages/IPython/kernel/zmq/session.py
EMPTY_BYTE_STRING=`python3 -c "print(''.encode())"`
PATCHED3=patches/patched3

$(PY3_VENV_BIN):
	@virtualenv --python=$(PY3) $(PY3_VENV)

py3deps: $(PY3_VENV_BIN)
	@. $(PY3_VENV)/bin/activate && \
	pip install -r requirements.txt
	@make $(PATCHED3)

$(PATCHED3):
	patch $(SESSION_SRC3) < patches/ierlang.patch
	touch $(PATCHED3)

py3shell-base:
	@echo "Starting IErlang Console..."
	. $(PY3_VENV)/bin/activate && \
	ERL_LIBS=$(ERLLIBS) \
	ipython3 console \
	--KernelManager.kernel_cmd=$(OPT_KERN_MGR_CMD) \
	--Session.key=$(EMPTY_BYTE_STRING) \
	--Session.keyfile=$(EMPTY_BYTE_STRING)

py3shell-no-deps:
	@rebar compile skip_deps=true
	@make PY3shell-base

py3shell: py3deps compile py3shell-base

py3clean:
	rm -rf $(PY3_VENV) $(PATCHED3)

demo3-base:
	@echo "Starting IErlang Notebook Demo..."
	@. $(PY3_VENV)/bin/activate && \
	ERL_LIBS=$(ERLLIBS) \
	ipython3 notebook $(IERLANG_DEMO) \
	--KernelManager.kernel_cmd=$(OPT_KERN_MGR_CMD) \
	--Session.key=$(EMPTY_BYTE_STRING) \
	--Session.keyfile=$(EMPTY_BYTE_STRING)

demo3: py3deps compile demo3-base

demo3-no-deps:
	@rebar compile skip_deps=true
	@make demo3-base

py3notebook: IERLANG_DEMO=notebooks
py3notebook: py3deps compile demo3-base
