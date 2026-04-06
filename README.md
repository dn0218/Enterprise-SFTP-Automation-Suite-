# 🚀 Enterprise SFTP Automation Suite  
### 企业级 SFTP 自动化文件交换系统

💡 Designed for real production environments with high reliability and idempotent processing.

A production-ready Shell-based automation framework for secure file exchange between internal systems and third-party platforms such as **JomPay** and **RPS**.

基于 Shell 脚本实现的生产级 SFTP 自动化解决方案，用于与第三方平台（如 JomPay、RPS）进行安全稳定的数据交换。

---

## 🧩 Architecture Overview | 架构说明
```bash
.
├── scripts/
│ ├── sftp_pull_jompay.sh # JomPay inbound processing
│ ├── sftp_put_rps.sh # RPS outbound upload
│ └── sftp_get_rps.sh # RPS inbound response
├── config/
│ └── crontab.txt # Scheduling reference
└── README.md
```


---

## 🔄 Core Workflows | 核心流程

### 1️⃣ JomPay Data Integration (Inbound)
**JomPay 数据拉取流程**

- Pull files from remote SFTP server  
- Download → Validate → Process → Archive  
- Perform **file integrity validation (footer check)**  
- Ensure **idempotent processing (no duplicate handling)**  

📌 Validation Rule: Last line must follow: 9 [TotalLines]


📌 Features:
- ✅ Footer validation  
- ✅ Duplicate prevention via log tracking  
- ✅ Remote file archival (`/done` directory)  

---

### 2️⃣ RPS Request Upload (Outbound)
**RPS 请求文件上传**

- Scan local upload directory  
- Batch upload files via SFTP  
- Automatically move uploaded files to backup  

📌 Features:
- ✅ Dynamic batch command generation (`mktemp`)  
- ✅ Auto backup (`/bak`)  
- ✅ Fail-safe logging  

---

### 3️⃣ RPS Response Handling (Inbound)
**RPS 返回文件处理**

- Monitor remote response directory  
- Download new files only  
- Prevent duplicate downloads  

📌 Features:
- ✅ Idempotent download logic  
- ✅ Lightweight log-based tracking  
- ✅ Safe re-execution (Cron-friendly)  

---

## ⚙️ Deployment Guide | 部署指南

### 1. Grant Permissions
```bash
chmod +x scripts/*.sh
chmod 600 /path/to/prod_sftp_id_rsa

### 2. Configure SSH Key Authentication
- Passwordless login required
- Ensure correct ownership & permissions

### 3. Setup Cron Jobs

(Refer config/crontab.txt)




