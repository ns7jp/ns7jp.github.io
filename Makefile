.PHONY: check evidence-preflight

check:
	node scripts/check-static-links.js
	node scripts/check-html-structure.js
	node scripts/check-site-quality.js
	node scripts/test-external-link-check.js
	bash -n scripts/capture-lab-evidence.sh support-scripts/linux-triage.sh

evidence-preflight:
	bash scripts/capture-lab-evidence.sh preflight
