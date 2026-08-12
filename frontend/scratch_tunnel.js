const localtunnel = require('localtunnel');
const http = require('http');

async function startTunnel() {
  const tunnel = await localtunnel({ 
    port: 5000, 
    local_host: '127.0.0.1'
  });

  console.log('TUNNEL_URL:' + tunnel.url);

  tunnel.on('close', () => {
    console.log('Tunnel closed, restarting...');
    setTimeout(startTunnel, 2000);
  });

  tunnel.on('error', (err) => {
    console.error('Tunnel error:', err.message);
    setTimeout(startTunnel, 2000);
  });

  // Keepalive: ping local server every 20 seconds to prevent tunnel timeout
  setInterval(() => {
    http.get('http://127.0.0.1:5000/get_current_user', (res) => {
      // Consume response to avoid socket hang
      res.resume();
    }).on('error', () => {});
  }, 20000);
}

startTunnel().catch(err => {
  console.error('Failed to start tunnel:', err);
});
