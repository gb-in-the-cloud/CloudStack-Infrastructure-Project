# CloudStack Infrastructure Project

> A production-style 3-tier cloud infrastructure deployed on AWS using Terraform for provisioning and Ansible for configuration management. In this project, I'm hosting a live PHP web page that connects to a MySQL database and displays student records.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Terraform — Infrastructure](#terraform--infrastructure)
- [Ansible — Configuration](#ansible--configuration)
- [MySQL — Database Setup](#mysql--database-setup)
- [PHP — Web Page](#php--web-page)
- [Accessing the Application](#accessing-the-application)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)
- [Author](#author)

---

## Overview

This project provisions and configures three EC2 instances on AWS:

| Server | Role | Access |
|---|---|---|
| Ansible Server | Control node — manages all servers | Public IP |
| Web App Server | Apache + PHP — serves the web page | Public IP |
| DB Server | MySQL 8.4 — stores student records | Private IP only |

The web page displays the server hostname, IP address, and a live table of student records pulled from the MySQL database — all connected via private networking inside the AWS VPC.

---

## Architecture

```
Internet
    │
    ▼  HTTP (port 80)
┌─────────────────────────┐
│   Web App Server        │  EC2 t3.micro — Ubuntu 26.04
│   Apache + PHP          │  Public IP: 15.188.5.112
│   /var/www/html/        │
└────────────┬────────────┘
             │ MySQL port 3306 (private only)
             ▼
┌─────────────────────────┐
│   DB Server             │  EC2 t3.micro — Ubuntu 26.04
│   MySQL 8.4             │  Private IP: ***********
│   studentdb             │
└─────────────────────────┘

┌─────────────────────────┐
│   Ansible Server        │  EC2 t3.micro — Ubuntu 26.04
│   Control Node          │  Public IP: 15.237.252.188
│   Manages both servers  │
└─────────────────────────┘

Region: AWS eu-west-3 (Paris)
```

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **Terraform** | Provision EC2 instances, Security Groups, Elastic IPs |
| **Ansible** | Install and configure Apache, PHP, and MySQL |
| **AWS EC2** | Cloud compute — 3x t3.micro Ubuntu instances |
| **Apache** | Web server — serves PHP on port 80 |
| **PHP** | Server-side scripting — connects to MySQL |
| **MySQL 8.4** | Relational database — stores student records |
| **Bash** | Server configuration and setup commands |

---

## Prerequisites

Before you begin, make sure you have the following installed and configured:

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.5+
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- An AWS account with EC2 permissions
- An SSH key pair created in AWS (eu-west-3 region)
- A `.pem` private key file stored locally

```bash
# Verify Terraform is installed
terraform version

# Verify AWS CLI is configured
aws sts get-caller-identity

# Configure AWS credentials if needed
aws configure
```

---

## Project Structure

```
CloudStack-Infrastructure-Project/
│
├── terraform/
│   ├── provider.tf          # AWS provider configuration (eu-west-3)
│   ├── secgroup.tf          # Security Groups — web-sg and db-sg
│   ├── instances.tf         # EC2 instances — ansible, webapp, db
│   └── eip.tf               # Elastic IPs for fixed public addresses
│
├── ansible/
│   ├── ansible.cfg          # Ansible configuration
│   ├── inventory.ini        # Web and DB server IP addresses
│   ├── apache-php.yml       # Playbook — installs Apache and PHP
│   └── install-mysql.yml    # Playbook — installs MySQL
│
├── app/
│   └── index.php            # PHP web page — displays DB records
│
└── README.md
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/cloudstack-infrastructure-project.git
cd cloudstack-infrastructure-project
```

### 2. Add Your PEM Key

```bash
# Copy your key to the project directory
cp ~/Downloads/your-key.pem ./your-key.pem
chmod 400 ./your-key.pem
```

### 3. Update Variables

In `terraform/instances.tf`, update the key pair name to match yours:

```hcl
key_name = "your-key-pair-name"   # Must match key pair in AWS Console
```

---

## Terraform — Infrastructure

### Deploy All Infrastructure

```bash
cd terraform/

# Initialise Terraform
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

### What Gets Created

```
✅ Security Group: web-sg   — SSH (22) + HTTP (80) open
✅ Security Group: db-sg    — MySQL (3306) from web-sg only
✅ EC2 Instance: ansible    — t3.micro, Ubuntu 26.04
✅ EC2 Instance: webapp     — t3.micro, Ubuntu 26.04
✅ EC2 Instance: db         — t3.micro, Ubuntu 26.04
✅ Elastic IPs              — Fixed public IPs for all instances
```

### Destroy Infrastructure (When Done)

```bash
terraform destroy
```

> ⚠️ Always run `terraform destroy` when finished to avoid AWS charges.

---

## Ansible — Configuration

All Ansible commands are run from the **Ansible server** after SSHing in.

### SSH Into the Ansible Server

```bash
ssh -i ./your-key.pem ubuntu@<ansible-public-ip>
```

### Copy Your Key to Ansible Server

```bash
scp -i ./your-key.pem \
    ./your-key.pem \
    ubuntu@<ansible-public-ip>:/home/ubuntu/.ssh/your-key.pem
```

### Update inventory.ini

```ini
[webservers]
<webapp-private-ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem

[dbservers]
<db-private-ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

### Run Playbooks

```bash
# Install Apache + PHP on web server
ansible-playbook apache-php.yml -i inventory.ini

# Install MySQL on DB server
ansible-playbook install-mysql.yml -i inventory.ini

# Test connectivity
ansible all -m ping -i inventory.ini
```

---

## MySQL — Database Setup

SSH into the DB server from the Ansible server:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<db-private-ip>
```

### Create the Database and Table

```sql
sudo mysql

CREATE DATABASE studentdb;
USE studentdb;

CREATE TABLE students (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

INSERT INTO students (name) VALUES ('Oluwagbenga Oyewole');
INSERT INTO students (name) VALUES ('John Doe');
INSERT INTO students (name) VALUES ('William Ojoor');

SELECT * FROM students;
EXIT;
```

### Create a Remote User for the Web App

```sql
sudo mysql

CREATE USER 'webuser'@'%' IDENTIFIED BY 'YourPassword!';
GRANT SELECT, INSERT ON studentdb.* TO 'webuser'@'%';
FLUSH PRIVILEGES;
EXIT;
```

### Allow Remote Connections

```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

# Change:
bind-address = 127.0.0.1
# To:
bind-address = 0.0.0.0

sudo systemctl restart mysql
```

---

## PHP — Web Page

### Deploy index.php to the Web Server

```bash
sudo nano /var/www/html/index.php
```

Update these variables at the top of the file:

```php
$db_host     = "<db-private-ip>";     
$db_user     = "webuser";             
$db_password = "YourPassword!";       
$db_name     = "studentdb";           
```

### Restart Apache

```bash
sudo systemctl restart apache2
```

---

## Accessing the Application

Once everything is deployed and configured:

```
http://<webapp-public-ip>/index.php
```

The page displays:
- Your name
- The server hostname and IP
- A live table of student records from MySQL

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| `Permission denied (publickey)` | Wrong key or bad permissions | `chmod 400 your-key.pem` |
| `Connection timed out` on SSH | Port 22 blocked in Security Group | Add SSH rule `0.0.0.0/0` in AWS Console |
| `InvalidKeyPair.NotFound` | Key name mismatch in Terraform | Verify key name with `aws ec2 describe-key-pairs` |
| `Can't connect to MySQL` | Wrong IP or port 3306 blocked | Check db-sg has port 3306 open from web-sg |
| `Host not allowed` on MySQL | User created with wrong host | Recreate user with `'webuser'@'%'` |
| PHP page blank or error | PHP syntax issue | Check `sudo tail -20 /var/log/apache2/error.log` |
| `t3.micro not free tier` | Wrong instance type | Use `t2.micro` only |

---

## Security Notes

- The DB server has **no public IP** — it is only reachable from within the VPC
- MySQL port 3306 is open **only from the web server security group** — not from the internet
- SSH access uses **key pair authentication only** — password login is disabled
- For production use, restrict SSH to specific IPs instead of `0.0.0.0/0`
- Store database passwords in **AWS Secrets Manager** instead of hardcoding in PHP
- Use **HTTPS** with a valid SSL certificate for production web traffic

---

## Author
Oluwagbenga Oyewole
---

> Built with Terraform, Ansible, Apache, PHP, and MySQL on AWS EC2.