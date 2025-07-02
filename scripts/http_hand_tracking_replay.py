#!/usr/bin/env python3
"""
Replay hand tracking log files by sending the data to an HTTP server.
Maintains original timing between messages.
"""

import json
import logging
import time
import argparse
from pathlib import Path
from typing import Dict, Any, List
import requests
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class HandTrackingReplay:
    def __init__(self, server_url: str = "http://localhost:5000"):
        self.server_url = server_url.rstrip('/')
        self.session = requests.Session()
        
    def load_log_file(self, log_path: Path) -> List[Dict[str, Any]]:
        """Load and parse a log file."""
        if not log_path.exists():
            raise FileNotFoundError(f"Log file not found: {log_path}")
            
        entries = []
        with open(log_path, 'r') as f:
            for line in f:
                try:
                    entry = json.loads(line.strip())
                    entries.append(entry)
                except json.JSONDecodeError as e:
                    logger.warning(f"Failed to parse line: {e}")
                    
        logger.info(f"Loaded {len(entries)} entries from {log_path}")
        return entries
        
    def check_server_health(self) -> bool:
        """Check if the server is healthy."""
        try:
            response = self.session.get(f"{self.server_url}/health", timeout=2)
            if response.status_code == 200:
                data = response.json()
                logger.info(f"Server is healthy: {data}")
                return True
        except Exception as e:
            logger.error(f"Server health check failed: {e}")
        return False
        
    def replay_log(self, log_path: Path, speed: float = 1.0, loop: bool = False):
        """Replay a log file."""
        entries = self.load_log_file(log_path)
        
        # Filter out metadata entries and get data entries
        data_entries = [e for e in entries if e.get('data')]
        metadata_entries = [e for e in entries if e.get('type') in ['metadata', 'session_end']]
        
        if not data_entries:
            logger.warning("No data entries found in log file")
            return
            
        # Display metadata
        for meta in metadata_entries:
            if meta.get('type') == 'metadata':
                logger.info(f"Log session started at: {meta.get('datetime')}")
            elif meta.get('type') == 'session_end':
                logger.info(f"Log session ended with {meta.get('total_messages')} messages, duration: {meta.get('duration'):.2f}s")
                
        logger.info(f"Replaying {len(data_entries)} messages at {speed}x speed")
        
        iteration = 0
        while True:
            iteration += 1
            if not loop:
                logger.info("Starting replay...")
            else:
                logger.info(f"Starting replay iteration {iteration}...")
                
            start_time = time.time()
            first_timestamp = data_entries[0]['server_timestamp']
            
            for i, entry in enumerate(data_entries):
                # Calculate delay based on original timing
                original_delay = entry['server_timestamp'] - first_timestamp
                scaled_delay = original_delay / speed
                current_elapsed = time.time() - start_time
                
                # Wait if needed
                if scaled_delay > current_elapsed:
                    time.sleep(scaled_delay - current_elapsed)
                    
                # Send the data
                try:
                    response = self.session.post(
                        f"{self.server_url}/control",
                        json=entry['data'],
                        timeout=1
                    )
                    
                    if response.status_code == 200:
                        # Print progress
                        if (i + 1) % 10 == 0 or i == 0:
                            progress = (i + 1) / len(data_entries) * 100
                            logger.info(f"Progress: {i+1}/{len(data_entries)} ({progress:.1f}%)")
                    else:
                        logger.error(f"Server returned {response.status_code}: {response.text}")
                        
                except requests.exceptions.RequestException as e:
                    logger.error(f"Failed to send message {i+1}: {e}")
                    
            total_time = time.time() - start_time
            logger.info(f"Replay completed in {total_time:.2f}s")
            
            if not loop:
                break
                
            logger.info("Waiting 2 seconds before next iteration...")
            time.sleep(2)
            
    def list_logs(self, log_dir: Path):
        """List available log files."""
        log_files = sorted(log_dir.glob("hand_tracking_*.json"))
        
        if not log_files:
            logger.info("No log files found")
            return
            
        logger.info(f"Found {len(log_files)} log files:")
        for i, log_file in enumerate(log_files):
            # Get file info
            size = log_file.stat().st_size / 1024  # KB
            modified = datetime.fromtimestamp(log_file.stat().st_mtime)
            
            # Try to read message count
            message_count = 0
            try:
                with open(log_file, 'r') as f:
                    for line in f:
                        entry = json.loads(line)
                        if entry.get('data'):
                            message_count += 1
            except:
                pass
                
            print(f"{i+1}. {log_file.name} - {size:.1f}KB, {message_count} messages, {modified.strftime('%Y-%m-%d %H:%M:%S')}")

def main():
    parser = argparse.ArgumentParser(description="Replay hand tracking logs via HTTP")
    parser.add_argument('action', choices=['replay', 'list'], help='Action to perform')
    parser.add_argument('--log-file', help='Log file to replay')
    parser.add_argument('--log-dir', default='./logs', help='Directory containing log files')
    parser.add_argument('--server', default='http://localhost:5000', help='HTTP server URL')
    parser.add_argument('--speed', type=float, default=1.0, help='Playback speed multiplier')
    parser.add_argument('--loop', action='store_true', help='Loop the replay continuously')
    parser.add_argument('--latest', action='store_true', help='Use the latest log file')
    
    args = parser.parse_args()
    
    replay = HandTrackingReplay(server_url=args.server)
    log_dir = Path(args.log_dir)
    
    if args.action == 'list':
        replay.list_logs(log_dir)
        return
        
    # Check server health first
    if not replay.check_server_health():
        logger.error("Server is not responding. Please check the server is running.")
        return
        
    # Determine which log file to use
    if args.latest:
        log_files = sorted(log_dir.glob("hand_tracking_*.json"))
        if not log_files:
            logger.error("No log files found")
            return
        log_path = log_files[-1]
        logger.info(f"Using latest log file: {log_path}")
    elif args.log_file:
        log_path = Path(args.log_file)
    else:
        logger.error("Please specify --log-file or use --latest")
        return
        
    # Start replay
    try:
        replay.replay_log(log_path, speed=args.speed, loop=args.loop)
    except KeyboardInterrupt:
        logger.info("Replay interrupted by user")

if __name__ == '__main__':
    main()