const axios = require('axios');

const API_URL = 'http://localhost:3001/api/v1';
const CONCURRENT_REQUESTS = 50; 
const TOTAL_ROUNDS = 5;

async function runStressTest() {
  console.log(`🚀 Starting Stress Test: ${CONCURRENT_REQUESTS} concurrent requests x ${TOTAL_ROUNDS} rounds`);
  
  for (let round = 1; round <= TOTAL_ROUNDS; round++) {
    console.log(`\n--- Round ${round} ---`);
    const startTime = Date.now();
    
    const requests = Array(CONCURRENT_REQUESTS).fill().map((_, i) => {
      return axios.get(`${API_URL}/notices`, {
        headers: { 'Authorization': 'Bearer test_token' },
        validateStatus: false
      });
    });

    const results = await Promise.all(requests);
    const duration = Date.now() - startTime;

    const success = results.filter(r => r.status === 200).length;
    const rateLimited = results.filter(r => r.status === 429).length;
    const otherErrors = results.filter(r => r.status !== 200 && r.status !== 429).length;

    if (otherErrors > 0) {
      console.log(`Debug: First error status: ${results.find(r => r.status !== 200)?.status}`);
    }

    console.log(`Duration: ${duration}ms`);
    console.log(`✅ Success: ${success}`);
    console.log(`🛑 Rate Limited (429): ${rateLimited}`);
    console.log(`❌ Other Errors: ${otherErrors}`);

    if (rateLimited > 0) {
      console.log('ℹ️  Rate limiter is working correctly.');
    } else {
      console.warn('⚠️  No rate limiting triggered. Is the limit set higher than the test?');
    }

    // Small delay between rounds
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
}

runStressTest().catch(err => {
  console.error('Stress test failed:', err.message);
  if (err.message.includes('ECONNREFUSED')) {
    console.error('Error: Is the backend server running on port 3001?');
  }
});
