# Week 19 Dashboard Starter - Docker & Podman

This repository contains a **complete container application** for the Week 19 Docker & Podman homework.

## 📦 What's Included

### Application Files
- `index.html` - Complete system status dashboard with:
  - Real-time clock and uptime tracking
  - Interactive operations testing
  - Container runtime detection
  - Modern responsive design
  - Professional dashboard interface

### Container Configuration
- `Dockerfile` - Production-ready container definition
- `docker-compose.yml` - Multi-container orchestration
- `nginx.conf` - Advanced web server configuration

## 🎯 How to Use

### For Students:
```bash
# Clone the starter repository
git clone https://github.com/[teacher]/docker-dashboard-starter.git
cd docker-dashboard-starter

# Create your working branch  
git checkout -b homework-[your-name]

# Test basic deployment
docker build -t system-dashboard .
docker run -d --name test-dashboard -p 8080:80 system-dashboard
```

### Quick Deployment Commands:
```bash
# Docker deployment
docker build -t dashboard-docker .
docker run -d --name docker-app -p 8080:80 dashboard-docker

# Podman deployment
podman build -t dashboard-podman .
podman run -d --name podman-app -p 8081:80 dashboard-podman

# Docker Compose deployment
docker-compose up -d
```

## 🖥️ Application Features

### Dashboard Components:
- **Container Information** - Runtime detection and metadata
- **System Status** - Real-time monitoring and uptime
- **Operations Testing** - Interactive system operations
- **Quick Stats** - Performance counters and metrics

### Interactive Features:
- ✅ Test connectivity with simulated results
- ✅ Refresh system status with mock data
- ✅ Download system logs functionality
- ✅ Cache clearing operations
- ✅ Real-time clock and uptime counter

## 🔧 Technical Details

### Container Detection:
- Automatically detects Docker vs Podman
- Shows different badges for each runtime
- URL parameter support: `?type=Docker` or `?type=Podman`

### Health Checks:
- Built-in container health monitoring
- `/health` endpoint for status checks
- Nginx-level health validation

### Performance:
- Optimized nginx configuration
- Gzip compression enabled
- Static file caching
- Security headers included

## 📚 Learning Objectives

This application helps students learn:
- Container build and deployment processes
- Docker vs Podman practical differences
- docker-compose orchestration
- Nginx configuration and optimization
- Health checks and monitoring
- Container networking and port mapping

## 🎨 Customization Opportunities

Students can:
- ✅ Modify container badge styling
- ✅ Add their name to the dashboard
- ✅ Extend nginx configuration
- ✅ Add environment variable handling
- ✅ Create additional health endpoints

## 🔐 Security Features

- Non-root nginx user
- Security headers configuration
- Health check isolation
- Resource limiting ready

---

**🎓 ITS-24 DevOps Automation Course**  
*Week 19 - Docker & Podman Container Technology*

**🚀 Ready-to-deploy container application for hands-on learning!**
