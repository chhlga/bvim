#!/usr/bin/env node
/**
 * SonicPi Log Stream Client (Node.js)
 * 
 * Connect to the TCP streaming server and receive real-time log messages.
 */

const net = require('net');

const HOST = '127.0.0.1';
const PORT = 8765;

console.log(`Connecting to SonicPi stream at ${HOST}:${PORT}...`);

const client = net.createConnection({ host: HOST, port: PORT }, () => {
  console.log('Connected! Listening for messages...\n');
});

let buffer = '';

client.on('data', (data) => {
  buffer += data.toString();
  const lines = buffer.split('\n');
  buffer = lines.pop();
  
  lines.forEach(line => {
    if (!line.trim()) return;
    
    try {
      const msg = JSON.parse(line);
      
      const address = msg.address_raw || 'unknown';
      const timestamp = msg.timestamp || 0;
      const dataContent = msg.data || {};
      
      console.log(`[${address}] @ ${timestamp}`);
      console.log(`  Data:`, dataContent);
      console.log();
      
    } catch (err) {
      console.error('Failed to decode JSON:', err.message);
      console.error('Raw line:', line.substring(0, 100));
    }
  });
});

client.on('end', () => {
  console.log('\nConnection closed by server');
});

client.on('error', (err) => {
  if (err.code === 'ECONNREFUSED') {
    console.error(`Error: Could not connect to ${HOST}:${PORT}`);
    console.error('Make sure Neovim is running with a sonicpi file open');
  } else {
    console.error('Connection error:', err.message);
  }
  process.exit(1);
});

process.on('SIGINT', () => {
  console.log('\n\nDisconnecting...');
  client.end();
  process.exit(0);
});
