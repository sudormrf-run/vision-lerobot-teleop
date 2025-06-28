#!/usr/bin/env python3
"""
Simple WebSocket server for testing Vision Pro hand tracking data reception.
"""

import asyncio
import websockets
import json
import logging
from datetime import datetime
import os
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HandTrackingServer:
    def __init__(self, verbose=True, log_to_file=False, log_dir="logs"):
        self.clients = set()
        self.message_count = 0
        self.verbose = verbose  # Set to False for less detailed output
        self.log_to_file = log_to_file
        self.log_dir = Path(log_dir)
        self.log_file = None
        self.log_data = []
        
        if self.log_to_file:
            self._setup_logging()
    
    def _setup_logging(self):
        """Setup logging directory and file"""
        self.log_dir.mkdir(exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.log_dir / f"hand_tracking_{timestamp}.json"
        logger.info(f"Logging enabled. Data will be saved to: {self.log_file}")
        
    def _save_logs(self):
        """Save accumulated log data to file"""
        if self.log_to_file and self.log_data:
            with open(self.log_file, 'w') as f:
                json.dump({
                    "metadata": {
                        "start_time": self.log_data[0]["timestamp"] if self.log_data else None,
                        "end_time": self.log_data[-1]["timestamp"] if self.log_data else None,
                        "total_messages": len(self.log_data),
                        "version": "1.0"
                    },
                    "messages": self.log_data
                }, f, indent=2)
            logger.info(f"Saved {len(self.log_data)} messages to {self.log_file}")
        
    async def register(self, websocket):
        self.clients.add(websocket)
        logger.info(f"Client {websocket.remote_address} connected. Total clients: {len(self.clients)}")
        
    async def unregister(self, websocket):
        self.clients.remove(websocket)
        logger.info(f"Client {websocket.remote_address} disconnected. Total clients: {len(self.clients)}")
        
    async def handle_message(self, websocket, message):
        try:
            data = json.loads(message)
            self.message_count += 1
            
            # Store raw message for logging
            if self.log_to_file:
                self.log_data.append({
                    "message_id": self.message_count,
                    "received_at": datetime.now().timestamp(),
                    "data": data
                })
            
            # Log basic info
            timestamp = datetime.fromtimestamp(data.get('timestamp', 0))
            logger.info(f"Message #{self.message_count} at {timestamp.strftime('%H:%M:%S.%f')[:-3]}")
            
            # Check if it's a both hands message
            if 'leftHand' in data or 'rightHand' in data:
                left_joints = len(data.get('leftHand', {}).get('joints', [])) if data.get('leftHand') else 0
                right_joints = len(data.get('rightHand', {}).get('joints', [])) if data.get('rightHand') else 0
                logger.info(f"  Left hand: {left_joints} joints, Right hand: {right_joints} joints")
                
                # Define expected joint names in order (26 joints total - thumb has no metacarpal in ARKit)
                joint_names = [
                    # Thumb (4 joints - no metacarpal)
                    "thumb.knuckle", "thumb.intermediateBase", "thumb.intermediateTip", "thumb.tip",
                    # Index (5 joints)
                    "index.metacarpal", "index.knuckle", "index.intermediateBase", "index.intermediateTip", "index.tip",
                    # Middle (5 joints)
                    "middle.metacarpal", "middle.knuckle", "middle.intermediateBase", "middle.intermediateTip", "middle.tip",
                    # Ring (5 joints)
                    "ring.metacarpal", "ring.knuckle", "ring.intermediateBase", "ring.intermediateTip", "ring.tip",
                    # Little (5 joints)
                    "little.metacarpal", "little.knuckle", "little.intermediateBase", "little.intermediateTip", "little.tip",
                    # Forearm (2 joints)
                    "forearm.wrist", "forearm.arm"
                ]
                
                # Log joints data based on verbosity
                if self.verbose:
                    # Log all joints data
                    if data.get('leftHand') and left_joints > 0:
                        logger.info("  Left hand joints received:")
                        # Print all 26 joints
                        for i in range(left_joints):
                            if i < len(data['leftHand']['joints']):
                                joint = data['leftHand']['joints'][i]
                                joint_name = joint_names[i] if i < len(joint_names) else f"joint_{i}"
                                logger.info(f"    [{i:2d}] {joint_name:25s}: x={joint[0]:7.3f}, y={joint[1]:7.3f}, z={joint[2]:7.3f}")
                    
                    # Same for right hand
                    if data.get('rightHand') and right_joints > 0:
                        logger.info("  Right hand joints received:")
                        for i in range(right_joints):
                            if i < len(data['rightHand']['joints']):
                                joint = data['rightHand']['joints'][i]
                                joint_name = joint_names[i] if i < len(joint_names) else f"joint_{i}"
                                logger.info(f"    [{i:2d}] {joint_name:25s}: x={joint[0]:7.3f}, y={joint[1]:7.3f}, z={joint[2]:7.3f}")
                else:
                    # Compact output - just show key joints
                    if data.get('leftHand') and left_joints > 24:
                        wrist = data['leftHand']['joints'][24]  # wrist is at index 24 (25th joint)
                        thumb_tip = data['leftHand']['joints'][3]  # thumb tip is at index 3 (4th joint)
                        index_tip = data['leftHand']['joints'][8]  # index tip is at index 8 (9th joint)
                        logger.info(f"  Left - Wrist: ({wrist[0]:.3f}, {wrist[1]:.3f}, {wrist[2]:.3f}), " +
                                  f"Thumb tip: ({thumb_tip[0]:.3f}, {thumb_tip[1]:.3f}, {thumb_tip[2]:.3f}), " +
                                  f"Index tip: ({index_tip[0]:.3f}, {index_tip[1]:.3f}, {index_tip[2]:.3f})")
                
                # Check tracked joints using bitmask
                if 'trackedMask' in data.get('leftHand', {}):
                    mask = data['leftHand']['trackedMask']
                    tracked_count = bin(mask).count('1')
                    logger.info(f"  Left hand tracked joints: {tracked_count}/26 (mask: {mask:026b})")
            
            # Echo back a confirmation
            response = {
                "type": "ack",
                "messageId": self.message_count,
                "timestamp": datetime.now().timestamp()
            }
            await websocket.send(json.dumps(response))
            
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON received: {message[:100]}...")
        except Exception as e:
            logger.error(f"Error handling message: {e}")
            
    async def handle_client(self, websocket):
        await self.register(websocket)
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            await self.unregister(websocket)

async def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='WebSocket server for Vision Pro hand tracking')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show all joint details')
    parser.add_argument('--log', '-l', action='store_true', help='Log messages to file')
    parser.add_argument('--log-dir', default='logs', help='Directory for log files (default: logs)')
    parser.add_argument('--port', '-p', type=int, default=8765, help='Port to listen on (default: 8765)')
    
    args = parser.parse_args()
    
    # Create server with options
    server = HandTrackingServer(
        verbose=args.verbose,
        log_to_file=args.log,
        log_dir=args.log_dir
    )
    
    # Start server - listen on all interfaces
    host = "0.0.0.0"  # Listen on all available interfaces
    port = args.port
    
    # Get local IP addresses
    import socket
    hostname = socket.gethostname()
    local_ips = []
    try:
        # Get all IP addresses
        for ip in socket.getaddrinfo(hostname, None):
            if ip[0] == socket.AF_INET:  # IPv4
                local_ips.append(ip[4][0])
        # Also try to get IP directly
        local_ip = socket.gethostbyname(hostname)
        if local_ip not in local_ips:
            local_ips.append(local_ip)
    except:
        pass
    
    # Remove duplicates and localhost
    local_ips = list(set([ip for ip in local_ips if not ip.startswith('127.')]))
    
    logger.info(f"Starting WebSocket server on ws://{host}:{port}")
    if local_ips:
        logger.info(f"Connect from Vision Pro using:")
        for ip in local_ips:
            logger.info(f"  ws://{ip}:{port}")
    else:
        logger.info(f"Could not determine local IP. Use 'ifconfig' or 'ip addr' to find your IP address")
    logger.info("Press Ctrl+C to stop")
    if server.log_to_file:
        logger.info(f"Logging enabled - data will be saved to {server.log_dir}")
    
    try:
        async with websockets.serve(server.handle_client, host, port):
            await asyncio.Future()  # Run forever
    finally:
        # Save logs when server stops
        server._save_logs()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\nServer stopped")