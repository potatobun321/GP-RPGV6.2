const fs = require('fs');
const path = require('path');
const readline = require('readline');
const os = require('os');

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'YOUR-PC-IP';
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const ask = (query, defaultVal) => new Promise(resolve => {
  rl.question(`${query} [default: ${defaultVal}]: `, answer => {
    resolve(answer.trim() || defaultVal);
  });
});

async function runSetup() {
  console.log('\n====================================================');
  console.log('   .gitmobile - Interactive Setup Wizard            ');
  console.log('====================================================\n');

  const defaultPort = 3000;
  const portStr = await ask('1. Port to bind server to', defaultPort);
  const port = parseInt(portStr, 10) || defaultPort;

  const pin = await ask('2. Security PIN for mobile access (leave empty for none)', '');

  const config = {
    port,
    pin,
    host: '127.0.0.1',
    createdAt: new Date().toISOString()
  };

  const configPath = path.join(__dirname, 'config.json');
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');

  const localIp = getLocalIp();
  const username = os.userInfo().username || 'your-username';

  console.log('\n[SUCCESS] Configuration saved to .gitmobile/config.json\n');
  console.log('----------------------------------------------------');
  console.log('Termux Connection Instructions:');
  console.log('----------------------------------------------------');
  console.log('1. On your Android phone, open Termux.');
  console.log('2. Run this single command to create an encrypted tunnel:');
  console.log(`\n   ssh -N -L ${port}:127.0.0.1:${port} ${username}@${localIp}\n`);
  console.log(`3. Open Chrome or your browser on your phone and go to:`);
  console.log(`\n   http://localhost:${port}\n`);
  console.log('4. (Optional) Tap "Add to Home Screen" to use it like a native app!');
  console.log('====================================================\n');

  rl.close();
}

runSetup().catch(err => {
  console.error('Setup failed:', err);
  rl.close();
});
