.ONESHELL:

# If the first argument is "run"...
# ifeq (pre,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)
# endif

export ENV=`cat infra/.current_env.out`
export MAIN=scripts/run_terraform.sh

%:
	@bash scripts/run_terraform.sh $@ $(RUN_ARGS)


