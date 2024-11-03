import boto3
import os
import json
from datetime import datetime
import yfinance as yf
import numpy as np
from sklearn.linear_model import LinearRegression

# AWS SNS Configuration
AWS_REGION = "us-east-1"
topic_arn = "arn:aws:sns:us-east-1:236845892852:emailrole" #edit and update your SNS ARN
#preform aws configure and edit credentials file in ~/.aws/credentials
#make sure that python3, python3-pip is installed
#preform : pip3 install boto3 yfinance numpy scikit-learn
#add premmisions via IAM rule to the instance, add sns full access
sns_client = boto3.client('sns', region_name=AWS_REGION)

# Fetch stock data for the 10 stocks
stock_list = ['INTC', 'AAPL', 'GOOGL', 'AMZN', 'MSFT', 'TSLA', 'META', 'NFLX', 'NVDA', 'BABA']

def get_stock_data(ticker):
    try:
        stock_data = yf.download(ticker, period='5d', interval='1d')
        if len(stock_data) < 2:
            return {
                "ticker": ticker,
                "yesterday": "N/A",
                "today": "N/A",
                "predicted_tomorrow": "N/A"
            }

        prices = stock_data['Close'].values[-2:]
        X = np.array([1, 2]).reshape(-1, 1)
        y = prices
        model = LinearRegression()
        model.fit(X, y)
        next_day = np.array([[3]])
        predicted_price = model.predict(next_day)[0]

        return {
            "ticker": ticker,
            "yesterday": round(prices[0], 2),
            "today": round(prices[1], 2),
            "predicted_tomorrow": round(predicted_price, 2)
        }
    except Exception:
        return {
            "ticker": ticker,
            "yesterday": "N/A",
            "today": "N/A",
            "predicted_tomorrow": "N/A"
        }

def fetch_app_data():
    stock_predictions = [get_stock_data(ticker) for ticker in stock_list]
    most_valuable_stock = max(stock_predictions, key=lambda x: x['predicted_tomorrow'] if x['predicted_tomorrow'] != "N/A" else float('-inf'))
    return {
        "timestamp": str(datetime.now()),
        "stock_predictions": stock_predictions,
        "most_valuable_stock": most_valuable_stock
    }

def format_message(data):
    message = f"\nDaily Stock Report:\n"
    message += f"Timestamp: {data['timestamp']}\n\n"
    message += "Stock Predictions:\n"
    for stock in data['stock_predictions']:
        message += f"Ticker: {stock['ticker']}, Yesterday: {stock['yesterday']}, Today: {stock['today']}, Predicted Tomorrow: {stock['predicted_tomorrow']}\n"
    message += f"\nMost Valuable Stock to Buy: {data['most_valuable_stock']['ticker']} (Predicted Price: {data['most_valuable_stock']['predicted_tomorrow']})\n"
    return message

def send_email_via_sns(subject, message):
    try:
        response = sns_client.publish(
            TopicArn=topic_arn,
            Message=message,
            Subject=subject
        )
        print(f"Message sent. ID: {response['MessageId']}")
    except Exception as e:
        print(f"Error occurred: {str(e)}")

#cronjob command : crontab -e
#cronjob edit: 0 14 * * * /usr/bin/python3 /home/ec2-user/cron_email_script.py >> /home/ec2-user/cron_log.txt 2>&1
#cronjob test : crontab -l




def main():
    app_data = fetch_app_data()
    email_subject = "Daily Stock Predictions Report"
    email_message = format_message(app_data)
    send_email_via_sns(email_subject, email_message)

if __name__ == "__main__":
    main()