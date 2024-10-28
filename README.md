
![Logo](https://cdn.iconscout.com/icon/premium/png-256-thumb/stock-prediction-5915866-4918534.png)

# 📈 Stocks Prediction App - Technion DevOps Middle Project

AI Stock Trading is an advanced application that leverages artificial intelligence to forecast stock values and provide users with daily trading recommendations.

![App Screenshot](https://i.imgur.com/9kxAl64.png)

## 🛠 Dependencies

- **Terraform** 0.13.0+
- **AWS Provider** 5.0.0+
- **AWS CLI** 2.0.0+

## 🧑‍💻 Tech Stack

- Terraform
- Python
- AWS (S3, EC2, SNS, Lambda, ALB, CloudFront, etc.)
- MongoDB
- Monitoring systems (Prometheus, Grafana, Loki)
- CRON job

## 🚀 Installation

1. After cloning the repository, initialize and apply the Terraform configuration:

   ```bash
   terraform init
   terraform apply
   ```

2. Once deployed, perform the following steps on app instances 1 and 2:

   ```bash
   sudo docker stop ec2-user-stock-app-1
   sudo docker rm ec2-user-stock-app-1
   sudo docker run -d --name ec2-user-stock-app-1 -e MONGO_URI="mongodb://mongoIP:27017" -p 5001:5001 -p 8000:8000 gabecasis/stock-app:5
   ```

   > **Note:** Replace `mongoIP` with the IP address of the Mongo instance.

3. Update the monitoring system IPs (as these are dynamic) on each instance:

   ```bash
   sudo nano /home/ec2-user/grafana/provisioning/datasources/datasources.yml  # Add the app instance IPs
   sudo nano /home/ec2-user/prometheus/prometheus.yml  # Add the app instance IPs
   ```

4. Create the SNS topic and copy its ARN. Copy `cron_email_sns_script.py` to your app EC2 instance, then update the script with your SNS Topic ARN.

5. Configure AWS credentials on the app EC2 instance:

   ```bash
   aws configure
   ```

6. **Important:** Ensure the following dependencies are installed on the app EC2:

   ```bash
   sudo yum install python3 -y
   sudo yum install python3-pip -y
   sudo yum install aws-cli -y
   pip3 install boto3 yfinance numpy scikit-learn
   ```

7. Run the script:

   ```bash
   python3 cron_email_sns_script.py
   ```

   If you receive an email with the top 10 stocks, success!

8. To automate with CRON, set up the job to run daily at 17:00 GMT+3:

   ```bash
   crontab -e
   # Add the following line:
   0 14 * * * /usr/bin/python3 /home/ec2-user/cron_email_script.py >> /home/ec2-user/cron_log.txt 2>&1
   ```

   Verify with:

   ```bash
   crontab -l
   ```

   🎉 Your CRON job is all set!

### 🏗 Setting Up S3 and Lambda

1. Create a unique S3 bucket.
2. Set up a Lambda function:

   - Ensure it has permissions (e.g., an S3 access role).
   - Add the bucket as a trigger and copy the code from `Lambda.py`.
   - Add your SNS Topic ARN, deploy, and you're done! You’ll receive an email notification for every new file uploaded to the bucket.

## 📸 Screenshots
### 📹 YouTube Project Overview
[![Project Overview](https://img.youtube.com/vi/IO6zt6l1M1I/0.jpg)](https://www.youtube.com/watch?v=IO6zt6l1M1I)

![App Screenshot](https://i.imgur.com/gvsYXlS.jpeg)
![App Screenshot](https://i.imgur.com/y42TZO9.jpeg)

## 📜 License

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)


