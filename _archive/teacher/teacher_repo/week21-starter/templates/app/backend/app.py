from flask import Flask, jsonify
import os
import psycopg2
from datetime import datetime

app = Flask(__name__)


def get_db_connection():
    """Ühenda andmebaasiga"""
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'db'),
            database=os.getenv('DB_NAME', 'app'),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', 'secret')
        )
        return conn
    except Exception as e:
        print(f"Andmebaasi ühenduse viga: {e}")
        return None


@app.route('/')
def home():
    """Koduleht"""
    return jsonify({
        'message': 'Week 21 Homework Backend API',
        'endpoints': {
            '/api/status': 'Rakenduse staatus',
            '/api/db-test': 'Andmebaasi test',
            '/api/health': 'Tervise kontroll'
        }
    })


@app.route('/api/status')
def status():
    """Tagasta rakenduse staatus"""
    db_status = "Connected" if get_db_connection() else "Disconnected"

    return jsonify({
        'status': 'OK',
        'environment': os.getenv('NODE_ENV', 'development'),
        'database': db_status,
        'timestamp': datetime.now().isoformat(),
        'message': 'Week 21 Homework Backend töötab!',
        'version': '1.0.0'
    })


@app.route('/api/db-test')
def db_test():
    """Testi andmebaasi ühendust"""
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()
            cursor.close()
            conn.close()

            return jsonify({
                'status': 'success',
                'message': 'Andmebaasi ühendus töötab!',
                'database_version': version[0] if version else 'Unknown',
                'connection_info': {
                    'host': os.getenv('DB_HOST', 'db'),
                    'database': os.getenv('DB_NAME', 'app'),
                    'user': os.getenv('DB_USER', 'postgres')
                }
            })
        except Exception as e:
            return jsonify({
                'status': 'error',
                'message': f'Andmebaasi päringu viga: {str(e)}'
            }), 500
    else:
        return jsonify({
            'status': 'error',
            'message': 'Ei saa ühenduda andmebaasiga',
            'connection_info': {
                'host': os.getenv('DB_HOST', 'db'),
                'database': os.getenv('DB_NAME', 'app'),
                'user': os.getenv('DB_USER', 'postgres')
            }
        }), 500


@app.route('/api/health')
def health():
    """Tervise kontroll"""
    db_healthy = get_db_connection() is not None

    return jsonify({
        'status': 'healthy' if db_healthy else 'unhealthy',
        'database': 'connected' if db_healthy else 'disconnected',
        'timestamp': datetime.now().isoformat(),
        'uptime': 'running'
    })


@app.route('/api/info')
def info():
    """Süsteemi info"""
    return jsonify({
        'application': 'Week 21 Homework Backend',
        'framework': 'Flask',
        'python_version': os.sys.version,
        'environment_variables': {
            'DB_HOST': os.getenv('DB_HOST', 'not_set'),
            'DB_NAME': os.getenv('DB_NAME', 'not_set'),
            'DB_USER': os.getenv('DB_USER', 'not_set'),
            'NODE_ENV': os.getenv('NODE_ENV', 'development')
        }
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
