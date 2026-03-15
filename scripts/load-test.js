import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');
const requestCount = new Counter('request_count');

// Test configuration for 100k concurrent users simulation
export const options = {
  stages: [
    // Ramp-up: Gradually increase to 100k users over 10 minutes
    { duration: '2m', target: 10000 },   // Ramp to 10k
    { duration: '3m', target: 25000 },   // Ramp to 25k
    { duration: '5m', target: 50000 },   // Ramp to 50k
    { duration: '10m', target: 100000 }, // Ramp to 100k
    
    // Sustain: Maintain 100k users for 30 minutes
    { duration: '30m', target: 100000 },
    
    // Peak test: Spike to 120k for 5 minutes
    { duration: '5m', target: 120000 },
    { duration: '5m', target: 120000 },
    
    // Ramp-down: Gradually decrease
    { duration: '5m', target: 50000 },
    { duration: '3m', target: 10000 },
    { duration: '2m', target: 0 },
  ],
  
  thresholds: {
    // 95% of requests should complete within 2 seconds
    'http_req_duration': ['p(95)<2000'],
    
    // Error rate should be less than 1%
    'errors': ['rate<0.01'],
    
    // 99% of requests should succeed
    'http_req_failed': ['rate<0.01'],
  },
};

// Configuration
const BASE_URL = __ENV.BASE_URL || 'https://your-app.example.com';
const API_URL = `${BASE_URL}/api`;

// User scenarios with different weights
export default function () {
  const scenarios = [
    { weight: 40, fn: browseHomePage },
    { weight: 25, fn: searchProducts },
    { weight: 20, fn: viewProductDetails },
    { weight: 10, fn: addToCart },
    { weight: 5, fn: checkout },
  ];
  
  // Select scenario based on weight
  const random = Math.random() * 100;
  let cumulative = 0;
  
  for (const scenario of scenarios) {
    cumulative += scenario.weight;
    if (random <= cumulative) {
      scenario.fn();
      break;
    }
  }
  
  // Think time between requests (1-3 seconds)
  sleep(Math.random() * 2 + 1);
}

// Scenario 1: Browse home page
function browseHomePage() {
  const res = http.get(`${BASE_URL}/`);
  
  const success = check(res, {
    'home page loaded': (r) => r.status === 200,
    'response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
  responseTime.add(res.timings.duration);
  requestCount.add(1);
}

// Scenario 2: Search products
function searchProducts() {
  const searchTerms = ['laptop', 'phone', 'tablet', 'headphones', 'camera'];
  const term = searchTerms[Math.floor(Math.random() * searchTerms.length)];
  
  const res = http.get(`${API_URL}/search?q=${term}`, {
    headers: {
      'Accept': 'application/json',
    },
  });
  
  const success = check(res, {
    'search successful': (r) => r.status === 200,
    'has results': (r) => r.json('results') !== undefined,
    'response time < 1.5s': (r) => r.timings.duration < 1500,
  });
  
  errorRate.add(!success);
  responseTime.add(res.timings.duration);
  requestCount.add(1);
}

// Scenario 3: View product details
function viewProductDetails() {
  const productId = Math.floor(Math.random() * 10000) + 1;
  
  const res = http.get(`${API_URL}/products/${productId}`, {
    headers: {
      'Accept': 'application/json',
    },
  });
  
  const success = check(res, {
    'product loaded': (r) => r.status === 200,
    'has product data': (r) => r.json('id') !== undefined,
    'response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
  responseTime.add(res.timings.duration);
  requestCount.add(1);
}

// Scenario 4: Add to cart
function addToCart() {
  const productId = Math.floor(Math.random() * 10000) + 1;
  const quantity = Math.floor(Math.random() * 3) + 1;
  
  const payload = JSON.stringify({
    productId: productId,
    quantity: quantity,
  });
  
  const res = http.post(`${API_URL}/cart`, payload, {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });
  
  const success = check(res, {
    'added to cart': (r) => r.status === 200 || r.status === 201,
    'response time < 2s': (r) => r.timings.duration < 2000,
  });
  
  errorRate.add(!success);
  responseTime.add(res.timings.duration);
  requestCount.add(1);
}

// Scenario 5: Checkout
function checkout() {
  const payload = JSON.stringify({
    items: [
      { productId: 1, quantity: 1 },
      { productId: 2, quantity: 2 },
    ],
    shippingAddress: {
      street: '123 Main St',
      city: 'San Francisco',
      state: 'CA',
      zip: '94102',
    },
    paymentMethod: 'credit_card',
  });
  
  const res = http.post(`${API_URL}/checkout`, payload, {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });
  
  const success = check(res, {
    'checkout successful': (r) => r.status === 200 || r.status === 201,
    'has order id': (r) => r.json('orderId') !== undefined,
    'response time < 3s': (r) => r.timings.duration < 3000,
  });
  
  errorRate.add(!success);
  responseTime.add(res.timings.duration);
  requestCount.add(1);
}

// Summary handler
export function handleSummary(data) {
  return {
    'load-test-results.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const enableColors = options.enableColors || false;
  
  let summary = '\n';
  summary += `${indent}Test Summary:\n`;
  summary += `${indent}=============\n`;
  summary += `${indent}Duration: ${data.state.testRunDurationMs / 1000}s\n`;
  summary += `${indent}Total Requests: ${data.metrics.http_reqs.values.count}\n`;
  summary += `${indent}Request Rate: ${data.metrics.http_reqs.values.rate.toFixed(2)}/s\n`;
  summary += `${indent}Average Response Time: ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms\n`;
  summary += `${indent}95th Percentile: ${data.metrics.http_req_duration.values['p(95)'].toFixed(2)}ms\n`;
  summary += `${indent}99th Percentile: ${data.metrics.http_req_duration.values['p(99)'].toFixed(2)}ms\n`;
  summary += `${indent}Error Rate: ${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%\n`;
  
  return summary;
}

/*
 * USAGE:
 * 
 * 1. Install k6: https://k6.io/docs/getting-started/installation/
 * 
 * 2. Run the test:
 *    k6 run --out json=results.json load-test.js
 * 
 * 3. Run with custom configuration:
 *    BASE_URL=https://your-app.com k6 run load-test.js
 * 
 * 4. Run with different user counts:
 *    k6 run --vus 10000 --duration 30m load-test.js
 * 
 * 5. Run distributed test (using k6 cloud):
 *    k6 cloud load-test.js
 * 
 * MONITORING DURING TEST:
 * 
 * Watch cluster performance:
 *   watch -n 1 kubectl top nodes
 *   watch -n 1 kubectl top pods -n production
 * 
 * Monitor autoscaling:
 *   kubectl get hpa -n production -w
 * 
 * Check cluster autoscaler:
 *   kubectl logs -n kube-system -l app=cluster-autoscaler -f
 * 
 * EXPECTED RESULTS FOR 100K USERS:
 * 
 * - Request rate: ~50,000-100,000 req/s (depends on scenario mix)
 * - Average response time: < 500ms
 * - 95th percentile: < 2s
 * - Error rate: < 1%
 * - Pod count: 200-400 (with HPA configured)
 * - Node count: 80-150 (with cluster autoscaler)
 * 
 * TROUBLESHOOTING:
 * 
 * If error rate is high:
 * - Check pod resource limits
 * - Verify database connection pooling
 * - Check for SNAT port exhaustion
 * - Review application logs
 * 
 * If response time is high:
 * - Verify HPA is scaling pods
 * - Check node resource utilization
 * - Review database query performance
 * - Check for network bottlenecks
 */
