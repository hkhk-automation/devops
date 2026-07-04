# Week 13 Web Assets - Ansible Vault & Templates

This repository contains **web design assets** for the Week 13 Ansible homework.

## 📦 What's Included

### Templates
- `templates/index.html.j2` - Complete Jinja2 template with:
  - Vault variable integration
  - Conditional logic examples
  - Loop demonstrations
  - Modern responsive design
  - Professional styling

### Static Assets
- `static/style.css` - Additional CSS for customization

## 🎯 How to Use

### For Students:
```bash
# Copy assets to your homework project
git clone https://github.com/[teacher]/ansible-web-assets.git assets
cp -r assets/templates assets/static your-homework-directory/
rm -rf assets/
```

### Template Variables Used:
- `{{ vault_website_title }}` - From vault
- `{{ vault_student_name }}` - From vault  
- `{{ vault_mysql_password }}` - From vault (length only)
- `{{ vault_admin_password }}` - From vault (length only)
- `{{ vault_api_key }}` - From vault (length only)
- `{{ server_name }}` - From inventory
- `{{ admin_email }}` - From inventory
- `{{ ansible_* }}` - System facts

## 🎨 Customization Encouraged

Students should:
- ✅ Modify colors and styling in CSS
- ✅ Add their own vault variables to template
- ✅ Extend template with additional cards
- ✅ Practice Jinja2 syntax with new features

## 🔐 Security Note

Template demonstrates **secure vault usage**:
- ✅ Shows password **lengths** not actual passwords
- ✅ Uses vault variables safely in templates
- ✅ Demonstrates proper secret handling

## 📚 Learning Objectives

This template helps students learn:
- Ansible Vault integration with templates
- Jinja2 template syntax (loops, conditionals, filters)
- Professional web presentation
- Secure credential handling

---

**🎓 ITS-24 DevOps Automation Course**  
*Week 13 - Ansible Vault & Templates*
