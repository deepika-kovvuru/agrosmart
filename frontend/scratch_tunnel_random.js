const localtunnel = require('localtunnel');

(async () => {
  try {
    const tunnel = await localtunnel({ 
      port: 5000, 
      local_host: '172.23.23.155' 
    });

    console.log('Tunnel is active at:', tunnel.url);

    // Keep the process alive
    setInterval(() => {
      // Periodic check
    }, 1000);

    tunnel.on('close', () => {
      console.log('Tunnel closed');
    });
  } catch (err) {
    console.error('Error starting tunnel:', err);
  }
})();
