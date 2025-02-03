# AWS Web Application Deployment

This repository contains the setup and deployment process for a cloud-based web application using AWS EC2, Docker, PostgreSQL, and Payara Micro.

## Overview
This project sets up a simple web application on AWS using Amazon Elastic Compute Cloud (EC2) with Docker containers. It includes setting up a PostgreSQL database and deploying the application with Payara Micro.

## Architecture
- **EC2 Instance**: Amazon Linux 2 AMI (small-sized instance)
- **Storage**: EBS for persistent database storage
- **Docker**: Containers for PostgreSQL and Payara
- **Networking**: Security groups allow access to SSH (22), Web (8080, 8181), and Database (5432)

## Setup Instructions
### 1. Launch EC2 Instance
- Choose **Amazon Linux 2** as the AMI
- Use a **small-sized instance**
- Create and download an **RSA key pair**
- Set up **Security Groups** to allow:
  - SSH (22) from your IP
  - HTTP (8080, 8181) for application access
  - PostgreSQL (5432) for database
- Attach an **EBS Volume** for persistent storage

### 2. Mount Disk for Database
- SSH into the instance and format the volume:
  ```sh
  sudo mkfs -t ext3 /dev/xvdb
  ```
- Mount the disk and update `/etc/fstab`:
  ```sh
  echo "UUID=***** /data ext3 noatime 0 0" | sudo tee -a /etc/fstab
  sudo mkdir /data
  sudo mount /data
  ```

### 3. Install Docker
```sh
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
```
(Log out and log back in to apply the changes.)

### 4. Set Up PostgreSQL Database
```sh
docker network create --driver bridge cs548-network
docker pull postgres
docker run -d --name cs548db --network cs548-network -p 5432:5432 \ -v /data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=XXXXXX \ -e PGDATA=/var/lib/postgresql/data/pgdata postgres
```

### 5. Initialize Database User
```sh
docker run -it --rm --network cs548-network postgres /bin/bash
# Inside container:
createuser cs548user -P --createdb -h cs548db -U postgres
exit
```

### 6. Deploy Web Application
- Copy `chat-webapp.war` to EC2
- Create `Dockerfile` for Payara Micro:
  ```Dockerfile
  FROM payara/micro:6.2025.1-jdk21
  COPY --chown=payara:payara chat-webapp.war ${DEPLOY_DIR}
  CMD ["--contextroot", "chat", "--deploy", "/opt/payara/deployments/chat-webapp.war"]
  ```
- Build and run the container:
  ```sh
  docker build -t cs548/chat .
  docker run -d --name chat --network cs548-network -p 8080:8080 -p 8181:8181 \ -e DATABASE_USERNAME=cs548user -e DATABASE_PASSWORD=YYYYYY -e DATABASE=cs548 \ -e DATABASE_HOST=cs548db cs548/chat
  ```

### 7. Enable Auto-Start on Boot
Create `/etc/systemd/system/cs548db.service`:
```ini
[Unit]
Wants=docker.service
After=docker.service

[Service]
RemainAfterExit=yes
ExecStart=/usr/bin/docker start cs548db
ExecStop=/usr/bin/docker stop cs548db

[Install]
WantedBy=multi-user.target
```
Enable the service:
```sh
sudo systemctl enable cs548db
sudo systemctl start cs548db
```

Create `/etc/systemd/system/chat.service`:
```ini
[Unit]
Wants=docker.service
After=docker.service

[Service]
RemainAfterExit=yes
ExecStart=/usr/bin/docker start chat
ExecStop=/usr/bin/docker stop chat

[Install]
WantedBy=multi-user.target
```
Enable the service:
```sh
sudo systemctl enable chat
sudo systemctl start chat
```




