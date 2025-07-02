#!/usr/bin/env python3
"""
HTTP server for receiving hand tracking data from Vision Pro.
Logs all received data with timestamps for later replay.
"""

import json
import logging
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

from flask import Flask, request, jsonify
from werkzeug.serving import make_server
import threading

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

class HandTrackingServer:
    def __init__(self, host: str = "0.0.0.0", port: int = 5000, log_dir: str = "./logs"):
        self.host = host
        self.port = port
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Current log file
        self.log_file: Optional[Path] = None
        self.log_handle = None
        self.message_count = 0
        self.start_time = None
        
        # Server
        self.server = None
        self.server_thread = None
        
    def start_new_log(self):
        """Start a new log file for this session."""
        if self.log_handle:
            self.log_handle.close()
            
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.log_dir / f"hand_tracking_{timestamp}.json"
        self.log_handle = open(self.log_file, 'w')
        self.message_count = 0
        self.start_time = time.time()
        
        # Write metadata
        metadata = {
            "type": "metadata",
            "timestamp": self.start_time,
            "datetime": datetime.now().isoformat(),
            "version": "1.0"
        }
        self.log_handle.write(json.dumps(metadata) + '\n')
        self.log_handle.flush()
        
        logger.info(f"Started new log: {self.log_file}")
        
    def log_data(self, data: Dict[str, Any]):
        """Log received data to file."""
        if not self.log_handle:
            self.start_new_log()
            
        # Add server timestamp and message count
        log_entry = {
            "server_timestamp": time.time(),
            "message_index": self.message_count,
            "data": data
        }
        
        self.log_handle.write(json.dumps(log_entry) + '\n')
        self.log_handle.flush()
        self.message_count += 1
        
    def run(self):
        """Run the Flask server."""
        self.server = make_server(self.host, self.port, app)
        logger.info(f"HTTP server started on http://{self.host}:{self.port}")
        logger.info(f"Logging data to: {self.log_dir}")
        
        # Start server in thread
        self.server_thread = threading.Thread(target=self.server.serve_forever)
        self.server_thread.daemon = True
        self.server_thread.start()
        
        try:
            # Keep main thread alive
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Shutting down server...")
            self.shutdown()
            
    def shutdown(self):
        """Shutdown the server and close log file."""
        if self.server:
            self.server.shutdown()
            
        if self.log_handle:
            # Write closing metadata
            metadata = {
                "type": "session_end",
                "timestamp": time.time(),
                "datetime": datetime.now().isoformat(),
                "total_messages": self.message_count,
                "duration": time.time() - self.start_time if self.start_time else 0
            }
            self.log_handle.write(json.dumps(metadata) + '\n')
            self.log_handle.close()
            logger.info(f"Session ended. Total messages: {self.message_count}")

# Global server instance
server = HandTrackingServer()

# Flask routes
@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "ok",
        "message_count": server.message_count,
        "uptime": time.time() - server.start_time if server.start_time else 0,
        "log_file": str(server.log_file) if server.log_file else None
    })

@app.route('/control', methods=['POST'])
def control():
    """Main endpoint for receiving hand tracking data."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Log the data
        server.log_data(data)
        
        # Print summary
        if 'leftHand' in data or 'rightHand' in data:
            hands = []
            if data.get('leftHand'):
                hands.append("left")
            if data.get('rightHand'):
                hands.append("right")
            logger.info(f"Received hand data: {', '.join(hands)} - Message #{server.message_count}")
        else:
            logger.info(f"Received data - Message #{server.message_count}")
        
        return jsonify({
            "status": "ok",
            "message_index": server.message_count,
            "timestamp": time.time()
        })
        
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/status', methods=['GET'])
def status():
    """Get server status."""
    return jsonify({
        "status": "running",
        "message_count": server.message_count,
        "current_log": str(server.log_file) if server.log_file else None,
        "uptime": time.time() - server.start_time if server.start_time else 0
    })

@app.route('/reset', methods=['POST'])
def reset():
    """Start a new log file."""
    old_count = server.message_count
    server.start_new_log()
    
    return jsonify({
        "status": "reset",
        "previous_message_count": old_count,
        "new_log_file": str(server.log_file)
    })

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="HTTP server for hand tracking data")
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    parser.add_argument('--log-dir', default='./logs', help='Directory to save logs')
    
    args = parser.parse_args()
    
    global server
    server = HandTrackingServer(host=args.host, port=args.port, log_dir=args.log_dir)
    server.run()

if __name__ == '__main__':
    main()