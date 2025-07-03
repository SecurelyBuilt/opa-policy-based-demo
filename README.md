A security testing lab that demonstrates policy-based access control using Open Policy Agent (OPA) with Damn Vulnerable Web Application (DVWA). This project showcases how to implement external authorization policies for web applications using containerized services.
🏗️ Architecture Overview
This lab consists of three main components:

DVWA: A deliberately vulnerable web application for security testing
MySQL: Database backend for DVWA
OPA: Open Policy Agent for policy-based authorization decisions

📋 Prerequisites

Docker and Docker Compose installed
Basic understanding of REST APIs
Familiarity with JSON and policy concepts

🚀 Quick Start

Clone the repository
bashgit clone <your-repo-url>
cd dvwa-opa-lab

Create the policies directory
bashmkdir -p policies

Add the policy file

Copy the policy.rego file to the policies/ directory


Start the lab environment
bashdocker-compose up -d

Verify services are running
bash# Check all services
docker-compose ps

# Check OPA health
curl http://localhost:8181/health

# Check DVWA (may take a minute to initialize)
curl http://localhost:8080


🐳 Docker Compose Configuration
Services Breakdown
DVWA (Damn Vulnerable Web Application)
yamldvwa:
  image: vulnerables/web-dvwa:latest
  ports:
    - "8080:80"  # Web interface accessible on port 8080
  environment:
    - MYSQL_HOSTNAME=mysql
    - MYSQL_DATABASE=dvwa
    - MYSQL_USERNAME=dvwa
    - MYSQL_PASSWORD=p@ssw0rd
  depends_on:
    - mysql
  networks:
    - lab-network
Purpose: Provides a vulnerable web application for testing security policies
Access: http://localhost:8080
MySQL Database
yamlmysql:
  image: mysql:5.7
  environment:
    - MYSQL_ROOT_PASSWORD=p@ssw0rd
    - MYSQL_DATABASE=dvwa
    - MYSQL_USER=dvwa
    - MYSQL_PASSWORD=p@ssw0rd
  networks:
    - lab-network
Purpose: Database backend for DVWA
Access: Internal only (no external ports exposed)
OPA (Open Policy Agent)
yamlopa:
  image: openpolicyagent/opa:latest
  command:
    - "run"
    - "--server"              # Run as HTTP server
    - "--addr=0.0.0.0:8181"  # Listen on all interfaces
    - "--log-level=debug"    # Verbose logging
    - "--watch"              # Auto-reload policies on changes
    - "/policies"            # Policy directory
  volumes:
    - ./policies:/policies   # Mount local policies directory
  ports:
    - "8181:8181"           # OPA API accessible on port 8181
  networks:
    - lab-network
Purpose: Policy decision engine for authorization
Access: http://localhost:8181
Network Configuration

lab-network: Bridge network enabling inter-service communication
All services can communicate using service names as hostnames

📜 Policy Documentation
Current Policy (policy.rego)
regopackage dvwa.login

import rego.v1

# Default deny
default allow := false

# Allow only if username is "admin" and password is "password"
allow if {
    input.username == "admin"
    input.password == "password"
}

# Simple decision response
decision := {
    "allow": allow,
    "user": input.username
}
Policy Behavior
✅ Allows

Username: admin with Password: password
Only this exact combination will return "allow": true

❌ Blocks

Any other username/password combination
Missing username or password fields
Empty or null values
All other authentication attempts (default deny)

📊 Response Format
json{
  "result": {
    "allow": true/false,
    "user": "<input_username>"
  }
}
🧪 Testing the Policy
Method 1: Using curl
Test Valid Credentials
bashcurl -X POST http://localhost:8181/v1/data/dvwa/login/decision \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "username": "admin",
      "password": "password"
    }
  }'
Expected Response:
json{
  "result": {
    "allow": true,
    "user": "admin"
  }
}
Test Invalid Credentials
bashcurl -X POST http://localhost:8181/v1/data/dvwa/login/decision \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "username": "hacker",
      "password": "badpass"
    }
  }'
Expected Response:
json{
  "result": {
    "allow": false,
    "user": "hacker"
  }
}
Test Missing Fields
bashcurl -X POST http://localhost:8181/v1/data/dvwa/login/decision \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "username": "admin"
    }
  }'
Expected Response:
json{
  "result": {
    "allow": false,
    "user": "admin"
  }
}
Method 2: Using Postman
Setup

Create a new POST request
Set URL: http://localhost:8181/v1/data/dvwa/login/decision
Set Headers:

Content-Type: application/json



Test Case 1: Valid Login
Request Body (JSON):
json{
  "input": {
    "username": "admin",
    "password": "password"
  }
}
Expected Response: Status 200 OK
json{
  "result": {
    "allow": true,
    "user": "admin"
  }
}
Test Case 2: Invalid Username
Request Body (JSON):
json{
  "input": {
    "username": "wronguser",
    "password": "password"
  }
}
Expected Response: Status 200 OK
json{
  "result": {
    "allow": false,
    "user": "wronguser"
  }
}
Test Case 3: Invalid Password
Request Body (JSON):
json{
  "input": {
    "username": "admin",
    "password": "wrongpass"
  }
}
Expected Response: Status 200 OK
json{
  "result": {
    "allow": false,
    "user": "admin"
  }
}
🔍 Monitoring and Debugging
View OPA Logs
bashdocker-compose logs opa
Check Loaded Policies
bashcurl http://localhost:8181/v1/policies
View All Available Data
bashcurl http://localhost:8181/v1/data
Check Service Status
bash# All services
docker-compose ps

# OPA health check
curl http://localhost:8181/health

# MySQL connection (from inside network)
docker-compose exec dvwa mysql -h mysql -u dvwa -p
🛠️ Troubleshooting
Common Issues
1. OPA Returns Empty Response
Problem: Policy not loaded or syntax error
Solution:
bash# Check OPA logs
docker-compose logs opa

# Verify policy syntax
docker-compose exec opa opa fmt policies/policy.rego
2. Cannot Connect to Services
Problem: Services not fully started
Solution:
bash# Wait for services to initialize
docker-compose up -d
sleep 30

# Check service health
curl http://localhost:8181/health
curl http://localhost:8080
3. Policy Changes Not Applied
Problem: Policy file not mounted correctly
Solution:
bash# Ensure policy is in correct location
ls -la policies/

# Restart OPA to reload
docker-compose restart opa
🔧 Extending the Lab
Adding More Complex Policies
The current policy can be extended to include:

Multiple valid users
Password complexity requirements
Rate limiting
Time-based access controls
IP address restrictions
Failed attempt tracking

Example Enhanced Policy
rego# Add to policy.rego for more complex rules
valid_users := {"admin", "user1", "testuser"}

allow if {
    input.username in valid_users
    count(input.password) >= 8
    input.failed_attempts < 5
}
📚 Learning Resources

OPA Documentation
Rego Language Guide
DVWA Documentation
Docker Compose Reference

🔒 Security Notes
⚠️ This is a lab environment for educational purposes only

Uses default/weak credentials intentionally
Not suitable for production deployment
DVWA contains deliberate vulnerabilities
Run only in isolated/controlled environments
