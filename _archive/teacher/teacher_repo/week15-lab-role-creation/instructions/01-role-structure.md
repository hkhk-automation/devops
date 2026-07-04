# Lab 1: Role Structure Creation (30 min)

## 🎯 Objective
Create a professional nginx role following Ansible Galaxy standards.

## 📋 Prerequisites
- Ansible installed: `ansible --version`
- Basic understanding of YAML syntax

## 🚀 Step-by-Step Instructions

### Step 1: Environment Setup
```bash
# Create working directory
mkdir ~/ansible-roles-lab
cd ~/ansible-roles-lab
mkdir roles
cd roles
```

### Step 2: Generate Role Structure
```bash
# Use ansible-galaxy to create role skeleton
ansible-galaxy init nginx-webserver

# Verify structure
tree nginx-webserver/
```

**Expected output:**
```
nginx-webserver/
├── README.md
├── defaults/main.yml
├── handlers/main.yml  
├── meta/main.yml
├── tasks/main.yml
├── templates/
├── vars/main.yml
└── tests/
```

### Step 3: Understand Each Directory

| Directory | Purpose | What goes here |
|-----------|---------|----------------|
| `tasks/` | Main tasks | Installation, configuration steps |
| `defaults/` | Default variables | User-configurable settings |
| `vars/` | Internal variables | Role-specific constants |
| `templates/` | Jinja2 templates | Configuration files |
| `handlers/` | Service handlers | Restart/reload services |
| `meta/` | Role metadata | Dependencies, requirements |
| `tests/` | Testing | Test playbooks |

### Step 4: Configure Metadata
Edit `meta/main.yml`:
```yaml
---
galaxy_info:
  author: "ITS-24 Student"
  description: "Professional Nginx with SSL and virtual hosts"
  company: "ITS-24 DevOps Course"
  license: "MIT"
  min_ansible_version: "2.9"
  
  platforms:
    - name: Ubuntu
      versions: [focal, jammy]
    - name: Debian  
      versions: [buster, bullseye]
  
  galaxy_tags:
    - web
    - nginx
    - ssl
    - webserver

dependencies: []
```

## ✅ Success Criteria
- [ ] Role structure created with `ansible-galaxy init`
- [ ] All directories present and empty
- [ ] Metadata configured with your information
- [ ] Ready for next lab step

## 💡 Tips
- Use `tree` command to visualize structure
- Keep metadata accurate for potential Galaxy publishing
- Follow naming conventions (lowercase, hyphens)
