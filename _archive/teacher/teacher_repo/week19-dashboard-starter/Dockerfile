FROM nginx:alpine

# Copy application files
COPY index.html /usr/share/nginx/html/

# Environment variables for identification
ENV APP_NAME="System Status Dashboard"
ENV VERSION="1.0.0"

# Expose port
EXPOSE 80

# Health check to ensure container is healthy
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
