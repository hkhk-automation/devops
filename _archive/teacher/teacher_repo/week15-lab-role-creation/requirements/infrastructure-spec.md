# Infrastructure Specification - Week 15 Ansible Roles

## 🎯 Project Overview

You will build a **complete web infrastructure** using custom Ansible roles. This teaches you how to create reusable, modular automation components.

---

## 📋 Infrastructure Requirements

### 1. **Web Server Role** (`roles/webserver`)
**Purpose:** Deploy and configure Nginx web server

**Tasks you must implement:**
- ✅ Install nginx package
- ✅ Start and enable nginx service  
- ✅ Remove default site configuration
- ✅ Create custom site configuration from template
- ✅ Create web root directory with proper permissions
- ✅ Test nginx configuration syntax

**Configuration requirements:**
- Listen on port 80 and 443 (SSL)
- Serve files from `/var/www/html`
- Custom server name based on hostname
- Security headers for production readiness
- Access logging enabled

### 2. **Database Role** (`roles/database`)
**Purpose:** Deploy and configure PostgreSQL database

**Tasks you must implement:**
- ✅ Install PostgreSQL server and client
- ✅ Start and enable PostgreSQL service
- ✅ Create application database
- ✅ Create application user with proper permissions
- ✅ Configure PostgreSQL for local connections
- ✅ Test database connectivity

**Configuration requirements:**
- Database name: `webapp_db`
- Database user: `webapp_user`
- User password: Use Ansible Vault for security
- Allow local connections for application

### 3. **SSL Certificate Role** (`roles/ssl`)
**Purpose:** Generate and manage SSL certificates

**Tasks you must implement:**
- ✅ Install OpenSSL package
- ✅ Generate private key for SSL
- ✅ Create self-signed certificate
- ✅ Set proper file permissions (600 for key, 644 for cert)
- ✅ Create certificate directory structure

**Configuration requirements:**
- Certificate valid for 365 days
- Key size: 2048 bits
- Subject: Use variables for customization
- Files stored in `/etc/ssl/certs/` and `/etc/ssl/private/`

### 4. **Monitoring Role** (`roles/monitoring`)
**Purpose:** Install basic system monitoring

**Tasks you must implement:**
- ✅ Download and install Node Exporter
- ✅ Create systemd service for Node Exporter
- ✅ Start and enable monitoring service
- ✅ Configure firewall for monitoring port
- ✅ Create monitoring user (optional)

**Configuration requirements:**
- Node Exporter port: 9100
- Run as non-root user
- Auto-start on boot
- Basic system metrics collection

---

## 🏗️ Project Structure Requirements

### Directory Structure You Must Create:
```
ansible/
├── ansible.cfg                 # Ansible configuration
├── site.yml                   # Main playbook  
├── inventory/
│   └── local                   # Local inventory file
├── group_vars/
│   └── all.yml                 # Global variables
├── host_vars/                  # Host-specific variables (optional)
├── roles/
│   ├── webserver/
│   │   ├── tasks/main.yml      # Main tasks
│   │   ├── handlers/main.yml   # Service handlers
│   │   ├── templates/          # Jinja2 templates
│   │   ├── defaults/main.yml   # Default variables
│   │   ├── vars/main.yml       # Role variables
│   │   └── meta/main.yml       # Role metadata
│   ├── database/
│   │   └── [same structure]
│   ├── ssl/
│   │   └── [same structure]
│   └── monitoring/
│       └── [same structure]
├── requirements.yml            # Galaxy role dependencies
└── README.md                   # Your documentation
```

---

## 🔧 Technical Implementation Guidelines

### Variable Management:
- **Use defaults/main.yml** for configurable options
- **Use vars/main.yml** for role-specific constants  
- **Use group_vars/all.yml** for project-wide settings
- **Use Ansible Vault** for sensitive data (passwords, keys)

### Template Requirements:
- **Nginx configuration** - Custom template with SSL support
- **PostgreSQL config** - Basic security and connection settings
- **Systemd service** - For Node Exporter service definition

### Handler Usage:
- **restart nginx** - When configuration changes
- **reload postgresql** - When database config changes
- **restart node_exporter** - When monitoring config changes

### Error Handling:
- **Use `failed_when`** for custom error conditions
- **Use `changed_when`** to control change reporting
- **Add validation tasks** to verify service status

---

## ✅ Acceptance Criteria

### Functional Requirements:
- [ ] **HTTPS access works** - `curl -k https://localhost`
- [ ] **Database accepts connections** - Application can connect
- [ ] **Monitoring endpoint responds** - `curl http://localhost:9100/metrics`
- [ ] **All services auto-start** - Survive reboot
- [ ] **Idempotent execution** - Can run multiple times safely

### Code Quality Requirements:
- [ ] **Follow Ansible best practices** - Use handlers, proper task names
- [ ] **Variables properly organized** - Defaults vs vars vs group_vars
- [ ] **Templates use Jinja2 features** - Variables, conditionals, loops
- [ ] **Role dependencies defined** - In meta/main.yml if needed
- [ ] **Documentation complete** - README explains usage

### Security Requirements:
- [ ] **SSL certificates properly secured** - Correct file permissions
- [ ] **Database passwords vaulted** - Not in plain text
- [ ] **Services run as appropriate users** - Non-root where possible
- [ ] **Firewall considerations** - Document required ports

---

## 🎓 Learning Objectives

By completing this project, you will:

### Master Ansible Role Architecture:
- Understand the purpose of each role directory
- Learn how to organize tasks, handlers, and templates
- Practice variable management and precedence

### Develop Infrastructure Skills:
- Configure web servers with SSL
- Manage database installations and users
- Implement basic monitoring solutions
- Handle service dependencies

### Build Professional Practices:
- Write idempotent automation code
- Create reusable, parameterized roles
- Document infrastructure decisions
- Test and validate deployments

---

**🚀 Ready to build professional infrastructure automation!**

*Next: Review the step-by-step guides in the `templates/` directory*
