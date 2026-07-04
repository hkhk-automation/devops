# Week 15 LAB - Ansible Role Creation Guide

This repository contains **step-by-step instructions** for creating professional Ansible roles during the 2-hour lab session.

## 🎯 Lab Objectives (2h)

Students will **CREATE from scratch:**
- ✅ Professional nginx role following Galaxy standards
- ✅ Multi-OS support (Ubuntu/Debian)
- ✅ SSL certificate management
- ✅ Virtual hosts configuration
- ✅ Role documentation and testing

## 📋 What Students Learn

### Role Creation Process:
- **Role structure** - Understanding each directory's purpose
- **ansible-galaxy init** - Generating role scaffolding
- **Role variables** - defaults vs vars vs meta
- **Template creation** - Jinja2 for dynamic configs
- **Handler usage** - Service management best practices

### Professional Practices:
- **Galaxy standards** - Publishing-ready role structure
- **Role documentation** - README and meta.yml
- **Testing approaches** - Validating role functionality
- **Variable organization** - Maintainable role design

## 🚀 How to Use This Repository

### For Instructors:
- Use `instructions/` guides for step-by-step teaching
- `examples/` contains code snippets for demonstration
- `templates/` has starting templates for students
- `tests/` provides validation scripts

### For Students:
- Follow along with instructor
- Create your own role structure using the guides
- Reference examples when stuck
- Test your role using provided scripts

## 📁 Repository Structure

```
ansible-roles-lab/
├── README.md                           # This file
├── instructions/                       # Step-by-step guides
│   ├── 01-role-structure.md           # Understanding role anatomy
│   ├── 02-creating-tasks.md           # Writing tasks and handlers
│   ├── 03-template-creation.md        # Jinja2 templating
│   ├── 04-variables-management.md     # Role variables
│   └── 05-testing-validation.md       # Testing your role
├── examples/                          # Code examples for reference
│   ├── task-examples.yml             # Sample tasks
│   ├── handler-examples.yml          # Sample handlers
│   └── template-examples.j2          # Template patterns
├── templates/                         # Starting templates
│   ├── role-skeleton/                # Basic role structure
│   └── nginx-config-template.j2      # Nginx config starter
└── tests/                            # Testing and validation
    ├── test-role.yml                 # Test playbook
    └── validate-setup.sh             # Environment validation
```

---

**🎓 ITS-24 DevOps Automation Course**  
*Week 15 LAB - Learn by Creating Ansible Roles*

**👨‍🏫 Instructor-guided hands-on role development**