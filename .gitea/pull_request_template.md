Issue: #

### What changed

Facts only, 2-3 sentences, not one adjective: the files, the numbers, links
to the artifacts.

### How it was proven

Facts only, 2-3 sentences: the command, what it printed, the link to the run.

`.\recipe.ps1 test` is green, and:

- [ ] the files changed are the ones named above, and no others
- [ ] tests changed together with the behaviour they prove
- [ ] new PowerShell parses in 5.1, has no BOM, and checks `$LASTEXITCODE`
      after every native call
