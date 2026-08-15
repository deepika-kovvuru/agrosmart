# -*- coding: utf-8 -*-
"""
AGROSMART Flask Backend Application Entrypoint Wrapper.
Imports and runs the core Flask application from agrosmart_app.py.
"""
import os
from agrosmart_app import app

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
