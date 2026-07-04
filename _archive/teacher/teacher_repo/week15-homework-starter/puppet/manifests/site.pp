# ===========================================
# PUPPET SITE MANIFEST - STUDENT LEARNING EXERCISE
# ===========================================
#
# This is a MINIMAL starter. You need to EXTEND it with:
# 1. SSL certificate generation (exec with openssl)
# 2. HTTPS configuration (nginx template)
# 3. Virtual hosts support (multiple sites)
# 4. Database setup (postgresql resources)
#
# LEARNING GOALS:
# - Learn Puppet resources (package, service, file, exec)
# - Learn Puppet templates (ERB syntax)
# - Learn SSL certificate generation
# - Learn database administration
# ===========================================

# TODO: Add SSL certificate generation
# TODO: Add nginx configuration with HTTPS
# TODO: Add virtual hosts setup
# TODO: Add database creation and user setup

# Basic nginx installation
package { 'nginx':
  ensure => installed,
}

service { 'nginx':
  ensure  => running,
  enable  => true,
  require => Package['nginx'],
}

# Basic postgresql installation
package { 'postgresql':
  ensure => installed,
}

service { 'postgresql':
  ensure  => running,
  enable  => true,
  require => Package['postgresql'],
}
