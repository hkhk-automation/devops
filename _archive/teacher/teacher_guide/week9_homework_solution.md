# Week 9 Homework Solution

## Correct Flow: feature → develop → main

## Setup
```bash
git clone https://github.com/USERNAME/its-git-demo.git
cd its-git-demo
echo "# Git Demo" > README.md
echo "*.log" > .gitignore
git add . && git commit -m "initial setup" && git push origin main
```

```bash
git checkout -b develop && git push -u origin develop
git checkout -b feature/system-info

# Create script
cat > system_info.sh << 'EOF'
#!/bin/bash
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Directory: $(pwd)"
df -h
EOF
chmod +x system_info.sh

# Create docs
echo "# Usage: ./system_info.sh" > USAGE.md

# Create CI
mkdir -p .github/workflows
cat > .github/workflows/test.yml << 'EOF'
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - run: bash -n system_info.sh && ./system_info.sh
EOF

git add . && git commit -m "feat: system info script"
git push origin feature/system-info
```

## GitHub Steps
1. Create Issues #1 & #2
2. Create PR: `feature/system-info` → `develop`
3. Merge PR
4. Cleanup: `git branch -d feature/system-info`

## Advanced Git
```bash
# Create conflict
git checkout develop
echo "Develop version" >> README.md
git add . && git commit -m "develop update"

git checkout main  
echo "Main version" >> README.md
git add . && git commit -m "main update"

git merge develop  # CONFLICT!

# Resolve conflict
echo "Combined version" > README.md
git add . && git commit -m "resolve conflict"

# Rebase demo
git checkout -b feature/docs
echo "# Contributing" > CONTRIBUTING.md
git add . && git commit -m "docs: contributing"
git rebase main && git checkout main && git merge feature/docs

# Release
git tag v1.0.0 && git push origin v1.0.0
```

**Key Fix:** Always `feature` → `develop` → `main`


### Issues Creation (via GitHub web interface)
```bash
Issue #1: "Add system info script"
Labels: enhancement
Description: Create system info script showing date, user, disk, memory
Acceptance: [ ] Script runs, [ ] Shows info, [ ] Has docs, [ ] Executable

Issue #2: "Improve documentation" 
Labels: documentation
Description: Better project documentation
Acceptance: [ ] README explains purpose, [ ] Usage guide complete, [ ] Examples provided
```

## Git Workflow
Feature branches → develop → main
```bash
main          ──●────●─────●──   (Production)
                 │    │     │
develop          ●────●─────●──   (Integration)  
                 │    │     
feature/docs     ●────●           (Features)
feature/script   ●────●           (Features)
```