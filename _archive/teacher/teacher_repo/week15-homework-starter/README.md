# Week 15 Homework: Ansible vs Puppet Comparison

## 🎯 Learning Objectives

This homework teaches you to:
- **Extend existing infrastructure code** with new features
- **Compare Ansible and Puppet** in practice
- **Learn SSL certificate generation** and HTTPS configuration
- **Learn database setup** and user management
- **Understand configuration management** workflows

## 📋 What You're Building

You'll extend basic nginx + postgresql setup with:
- 🔐 **SSL certificates** (self-signed for testing)
- 🌐 **HTTPS configuration** (port 443)
- 🏠 **Virtual hosts** (multiple websites)
- 🗄️ **Database setup** (users, tables, permissions)
- 📊 **Basic monitoring** (health checks)

## 🚀 Getting Started

### Step 1: Understand the Starter Code
```bash
# Explore what's already there
ls -la ansible/roles/nginx/tasks/
ls -la ansible/roles/postgresql/tasks/

# Read the TODO comments in each file
cat ansible/roles/nginx/tasks/main.yml
cat ansible/roles/postgresql/tasks/main.yml
```

### Step 2: Read Requirements
```bash
# Detailed requirements
cat requirements.md
```

### Step 3: Start with Ansible
```bash
# Test the basic setup first
cd vagrant/
vagrant up ansible-vm
vagrant ssh ansible-vm

# Then extend it step by step
cd ../ansible/
# Add SSL tasks, templates, database setup...
```

## 📚 Learning Path

### Phase 1: Ansible Extension (50 min)
1. **Learn SSL certificate generation** - openssl commands
2. **Learn nginx configuration** - templates and virtual hosts  
3. **Learn database administration** - PostgreSQL setup
4. **Test your implementation** - verify HTTPS and DB work

### Phase 2: Puppet Implementation (50 min)
1. **Apply same concepts** in Puppet syntax
2. **Learn Puppet resources** - package, service, file, exec
3. **Learn Puppet templates** - ERB syntax
4. **Compare with Ansible** - which was easier?

### Phase 3: Comparison & Reflection (10 min)
- Which tool had better error messages?
- Which syntax did you prefer?
- Which deployment was faster?
- What would you choose for production?

## 🎯 Success Criteria

✅ **Both implementations work identically**
- Same HTTPS website accessible
- Same database with same tables
- Same file locations and permissions

✅ **You understand the differences**
- Ansible: imperative, YAML, agentless
- Puppet: declarative, DSL, agent-based

✅ **You can explain your choice**
- When would you use Ansible?
- When would you use Puppet?

## 💡 Tips for Success

- **Start small** - get basic SSL working first
- **Test frequently** - use vagrant for safe testing
- **Read error messages** - they guide you to solutions
- **Compare as you go** - notice syntax differences
- **Document your learning** - write notes in README.md

## 📖 Resources

- [Ansible Template Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)
- [Puppet File Resource](https://puppet.com/docs/puppet/latest/types/file.html)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [PostgreSQL Administration](https://www.postgresql.org/docs/current/admin.html)

---

**Remember:** This is about learning by doing! Don't just copy-paste - understand what each line does and why it's needed.
