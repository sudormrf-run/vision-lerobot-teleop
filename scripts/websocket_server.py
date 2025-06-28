#!/usr/bin/env python3
"""
Simple WebSocket server for testing Vision Pro hand tracking data reception.
"""

import asyncio
import websockets
import json
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HandTrackingServer:
    def __init__(self):
        self.clients = set()
        self.message_count = 0
        
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
            
            # Log basic info
            timestamp = datetime.fromtimestamp(data.get('timestamp', 0))
            logger.info(f"Message #{self.message_count} at {timestamp.strftime('%H:%M:%S.%f')[:-3]}")
            
            # Check if it's a both hands message
            if 'leftHand' in data or 'rightHand' in data:
                left_joints = len(data.get('leftHand', {}).get('joints', [])) if data.get('leftHand') else 0
                right_joints = len(data.get('rightHand', {}).get('joints', [])) if data.get('rightHand') else 0
                logger.info(f"  Left hand: {left_joints} joints, Right hand: {right_joints} joints")
                
                # Example: Extract palm position (wrist joint - typically index 24)
                if data.get('leftHand') and left_joints > 24:
                    left_wrist = data['leftHand']['joints'][24]
                    logger.info(f"  Left wrist position: x={left_wrist[0]:.3f}, y={left_wrist[1]:.3f}, z={left_wrist[2]:.3f}")
                
                if data.get('rightHand') and right_joints > 24:
                    right_wrist = data['rightHand']['joints'][24]
                    logger.info(f"  Right wrist position: x={right_wrist[0]:.3f}, y={right_wrist[1]:.3f}, z={right_wrist[2]:.3f}")
            
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
            
    async def handle_client(self, websocket, path):
        await self.register(websocket)
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            await self.unregister(websocket)

async def main():
    server = HandTrackingServer()
    
    # Start server - listen on all interfaces
    host = "0.0.0.0"  # Listen on all available interfaces
    port = 8765
    
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
    
    async with websockets.serve(server.handle_client, host, port):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\nServer stopped")