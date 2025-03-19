# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= shayne

UNAME := $(shell uname)
HOSTNAME := $(shell hostname -s)

# Settings
NIXBLOCKDEVICE ?= nvme0n1

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

switch:
ifeq ($(UNAME), Darwin)
	nix build ".#darwinConfigurations.${HOSTNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${HOSTNAME}"
else ifeq ($(HOSTNAME), m1nix)
	sudo nixos-rebuild switch --impure --flake .
else ifeq ($(HOSTNAME), m2nix)
	sudo nixos-rebuild switch --impure --flake .
else ifeq ($(HOSTNAME), lima)
	sudo nixos-rebuild switch --impure --flake .
else
	sudo nixos-rebuild switch --flake .
endif

test:
	sudo nixos-rebuild test --flake .

# bootstrap a brand new VM. The VM should have NixOS ISO on the CD drive
# and just set the password of the root user to "root". This will install
# NixOS. After installing NixOS, you must reboot and set the root password
# for the next step.
#
# NOTE(mitchellh): I'm sure there is a way to do this and bootstrap all
# in one step but when I tried to merge them I got errors. One day.
vm/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/$(NIXBLOCKDEVICE) -- mklabel gpt; \
		parted /dev/$(NIXBLOCKDEVICE) -- mkpart primary 512MiB -8GiB; \
		parted /dev/$(NIXBLOCKDEVICE) -- mkpart primary linux-swap -8GiB 100\%; \
		parted /dev/$(NIXBLOCKDEVICE) -- mkpart ESP fat32 1MiB 512MiB; \
		parted /dev/$(NIXBLOCKDEVICE) -- set 3 esp on; \
		mkfs.ext4 -L nixos /dev/$(NIXBLOCKDEVICE)p1; \
		mkswap -L swap /dev/$(NIXBLOCKDEVICE)p2; \
		mkfs.fat -F 32 -n boot /dev/$(NIXBLOCKDEVICE)p3; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixUnstable;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
  			services.openssh.enable = true;\n \
			services.openssh.passwordAuthentication = true;\n \
			services.openssh.permitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd; \
		reboot; \
	"

# after bootstrap0, run this to finalize. After this, do everything else
# in the VM unless secrets change.
vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"


# copy our secrets into the VM
vm/secrets:
	# GPG keyring
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='.#*' \
		--exclude='S.*' \
		--exclude='*.conf' \
		$(HOME)/.gnupg/ $(NIXUSER)@$(NIXADDR):~/.gnupg
	# SSH keys
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh

# copy the Nix configurations into the VM.
vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

# run the nixos-rebuild switch command. This does NOT copy files so you
# have to run vm/copy before.
vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake \"/nix-config#$.\" \
	"

# Build an ISO image
iso/nixos.iso:
	cd iso; ./build.sh

# Makefile for advanced testing scenarios
test-random:
	@echo "🚀 Initiating Enhanced Random Testing Protocol v2.0"
	@echo "┌──────────────────────────────────────"
	@for phase in "Quantum Initialization" "Probability Matrix" "Reality Distortion"; do \
		echo "│ Phase: $$phase"; \
		echo "│ Status: Processing..."; \
		sleep 1; \
		echo "│ Status: Complete ✓"; \
		echo "├──────────────────────────────────────"; \
	done
	@echo "└──────────────────────────────────────"
	@echo "🎉 Enhanced random test completed with quantum certainty"

generate-noise:
	@echo "🌈 Initiating Advanced Noise Generation v3.0"
	@for dimension in "temporal" "spatial" "quantum"; do \
		echo "Generating $$dimension noise:"; \
		for level in $$(seq 1 3); do \
			echo "  [$$dimension:$$level] Entropy level: $$(( $$RANDOM % 100 ))%"; \
			for sublevel in $$(seq 1 2); do \
				echo "    ↳ Sublevel $$sublevel: $$(( $$RANDOM % 1000 )) quantum fluctuations"; \
				sleep 0.5; \
			done; \
		done; \
	done
	@echo "🎵 Noise generation completed across all dimensions"

cleanup-nothing:
	@echo "🧹 Initiating Quantum Cleanup Protocol"
	@echo "Analyzing quantum state..."
	@for state in "superposition" "entangled" "collapsed"; do \
		echo "Cleaning up $$state state..."; \
		echo "  - Probability: $$(( $$RANDOM % 100 ))%"; \
		echo "  - Uncertainty: $$(( $$RANDOM % 42 ))%"; \
		sleep 1; \
	done
	@echo "✨ Quantum cleanup completed successfully"

test-matrix:
	@echo "🎲 Running Quantum Test Matrix v2.0"
	@echo "Matrix initialization..."
	@for dimension in "parallel" "quantum" "temporal"; do \
		for env in "dev" "staging" "prod" "quantum"; do \
			for test in "unit" "integration" "chaos" "quantum"; do \
				probability=$$(( $$RANDOM % 100 )); \
				echo "[$$dimension:$$env:$$test] P(success)=$$probability%"; \
				sleep 0.5; \
			done; \
		done; \
	done
	@echo "🌌 Quantum test matrix completed"

verify-random:
	@echo "🔍 Quantum Verification Protocol v2.0"
	@echo "Initializing quantum state..."
	@for i in $$(seq 1 3); do \
		state=$$(( $$RANDOM % 3 )); \
		case $$state in \
			0) echo "State $$i: Quantum verification passed (⚛️ stable)";; \
			1) echo "State $$i: Timeline divergence detected (🌀 unstable)";; \
			2) echo "State $$i: Reality anchor point established (⚡️ neutral)";; \
		esac; \
		sleep 1; \
	done
	@echo "🎯 Quantum verification complete"

quantum-test:
	@echo "⚛️ Initiating Quantum Testing Sequence"
	@echo "Establishing quantum entanglement..."
	@for particle in "electron" "photon" "qubit"; do \
		echo "Entangling $$particle..."; \
		probability=$$(( $$RANDOM % 100 )); \
		echo "  Quantum state: $$probability% coherent"; \
		sleep 1; \
	done
	@echo "🌌 Quantum test sequence complete"

.PHONY: test-random generate-noise cleanup-nothing test-matrix verify-random quantum-test
