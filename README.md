# Automated Threat Response on AWS with Terraform

This project demonstrates an event-driven, serverless security workflow on AWS that automatically detects and blocks malicious network activity in near real-time. The entire infrastructure is deployed and managed as code using Terraform.

## Project Summary

The system is designed to identify a common reconnaissance technique—a port scan—and automatically block the source IP address at the network edge, preventing further interaction. This moves beyond simple static defenses and creates an active, intelligent response mechanism.

---

## Architecture

The workflow is triggered by an attacker's actions and flows through several AWS services to neutralize the threat automatically.

 **Workflow:**
1.  **Detection:** An attacker port scans an EC2 instance. **AWS GuardDuty** analyzes VPC Flow Logs and detects this activity, generating a `Recon:EC2/Portscan` finding.
2.  **Alerting:** An **Amazon EventBridge** rule is configured to listen specifically for that GuardDuty finding.
3.  **Invocation:** Upon matching the finding, EventBridge invokes an **AWS Lambda** function.
4.  **Response:** The Python Lambda function parses the event, extracts the attacker's IP address, and adds it to an IP set in the **AWS WAF (Web Application Firewall)**, effectively blocking the IP.

---

## Technology Stack

This project utilizes a modern, cloud-native toolset:
* [cite_start]**Infrastructure as Code:** Terraform [cite: 23]
* [cite_start]**Cloud Provider:** AWS [cite: 23]
* [cite_start]**Security Services:** AWS GuardDuty, AWS WAF, AWS IAM [cite: 23, 25]
* [cite_start]**Compute:** AWS Lambda [cite: 23]
* [cite_start]**Automation:** Python (`boto3`) [cite: 28]
* **Event-Driven Architecture:** Amazon EventBridge

---

## How This Project Demonstrates My Capabilities

This project is a practical application of the skills and experience detailed on my resume.

* [cite_start]**Cloud & Infrastructure[cite: 23]:** It showcases my ability to architect and deploy a multi-service, event-driven solution on AWS. I used Terraform not just to build static infrastructure, but to codify a complex, dynamic workflow that connects several managed services.

* [cite_start]**Security Operations [cite: 24][cite_start]:** In my role as an IT Support Specialist, I analyzed SIEM, EDR, and IDS/IPS data to investigate and recommend remediation strategies[cite: 12, 14]. This project automates that entire process. It takes a security finding—similar to an alert I would analyze—and automatically executes the response, demonstrating a shift from manual analysis to proactive, code-driven defense.

* [cite_start]**Identity & Access Management (IAM)[cite: 25]:** The project required creating a precisely scoped IAM role for the Lambda function, granting it only the permissions necessary to modify the WAF and write logs. This implements the principle of least privilege, a core security concept.

* [cite_start]**Automation with Python[cite: 28]:** The heart of the response mechanism is a Python script that uses the AWS `boto3` library to interact with the WAF API. This highlights my ability to write functional code to perform security automation tasks.

---

## Setup & Deployment

The entire infrastructure can be deployed with a few commands.

1.  **Clone the repository:**
    ```bash
    git clone [your-repo-url]
    cd [your-repo-name]
    ```

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

3.  **Plan the deployment:**
    ```bash
    terraform plan
    ```

4.  **Apply the changes:**
    ```bash
    terraform apply
    ```
