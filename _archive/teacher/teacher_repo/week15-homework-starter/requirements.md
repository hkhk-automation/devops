# Requirements - What YOU need to implement

## 🎯 Overview

The starter code gives you **basic nginx + postgresql installation**. You need to **extend both Ansible and Puppet versions** with the same additional functionality.

---

## 📋 Ansible Requirements

### 1. Extend `roles/nginx/` 

**Currently has:** Basic nginx installation and service start

**YOU must add:**
- **SSL certificate generation** 
  - Create `/etc/ssl/certs/nginx.crt` and `/etc/ssl/private/nginx.key`  
  - Self-signed certificate, valid for 365 days
  - Proper file permissions (644 for cert, 600 for key)

- **HTTPS configuration**
  - Modify nginx config template to listen on port 443
  - SSL certificate and key paths in config
  - Redirect HTTP (port 80) to HTTPS

- **Virtual hosts support**
  - Template that can handle multiple sites
  - Document root: `/var/www/{{ site_name }}`
  - Create index.html for each site

### 2. Extend `roles/postgresql/`

**Currently has:** Basic postgresql installation

**YOU must add:**
- **Database creation**
  - Database name: `webapp_db`
  - Database user: `webapp_user` 
  - User password: `SecurePass123` (use variables)

- **Basic schema**
  - Create table: `users` with columns `id`, `name`, `email`
  - Grant all privileges to webapp_user

---

## 📋 Puppet Requirements

### 1. Extend `modules/nginx/`

**Currently has:** Basic nginx package and service

**YOU must add:**
- **SSL certificate generation**
  - Same as Ansible: generate self-signed cert and key
  - Use `exec` resource with openssl command
  - Proper file permissions with `file` resource

- **HTTPS configuration** 
  - Create nginx config template (ERB)
  - Listen on ports 80 and 443
  - SSL configuration in server block

- **Virtual hosts support**
  - ERB template for multiple sites
  - Same document root structure as Ansible

### 2. Extend `modules/postgresql/`

**Currently has:** Basic postgresql package

**YOU must add:**
- **Database and user setup**
  - Same database name and user as Ansible
  - Use postgresql puppet resources or exec commands

- **Basic schema**
  - Same table structure as Ansible
  - User permissions setup

---

## 🧪 Testing Requirements

### Both implementations must:

1. **HTTPS access works:**
   ```bash
   curl -k https://localhost
   # Should return webpage
   ```

2. **Database accepts connections:**
   ```bash
   sudo -u postgres psql -d webapp_db -c "\dt"
   # Should show users table
   ```

3. **Virtual host works:**
   ```bash
   curl -k https://localhost/
   # Should serve from /var/www/default/index.html
   ```

4. **Services survive reboot:**
   ```bash
   sudo systemctl status nginx postgresql
   # Both should be enabled and running
   ```

---

## 💡 Implementation hints

### For Ansible:
- Use `openssl_certificate` and `openssl_privatekey` modules if available
- Or use `command` module with openssl CLI
- Use `template` module for nginx config
- Use `postgresql_db` and `postgresql_user` modules for database

### For Puppet:
- Use `exec` resource for openssl commands  
- Use `file` resource for config templates
- Use `postgresql::server::db` if postgresql module available
- Or use `exec` with psql commands

### File locations:
- **SSL cert:** `/etc/ssl/certs/nginx.crt`
- **SSL key:** `/etc/ssl/private/nginx.key` 
- **Nginx config:** `/etc/nginx/sites-available/default`
- **Document root:** `/var/www/default/`

---

## ✅ When you're done

Both Ansible and Puppet should produce **identical results**:
- Same HTTPS website accessible
- Same database with same table
- Same file locations and permissions

**Then compare:** Which was easier to implement? Which had better error messages? Which syntax did you prefer?
