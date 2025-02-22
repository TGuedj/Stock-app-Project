variable "AWS_REGION" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "The AWS vpc name"
  type        = string
  default     = "sample"

}

variable "vpc_cidr" {
  description = "The AWS vpc cidr block"
  type        = string
  default     = "10.0.0.0/16"

}

variable "outsider_ip" {
  description = "The AWS vpc cidr block"
  type        = string
  default     = "0.0.0.0" 

}


variable "instance_names" {
  type    = list(string)
  default = ["instance-private-1", "instance-private-2", "instance-private-3", "instance-private-4"]
}




resource "aws_security_group" "instance_sg" {
  name        = "instance_security_group"
  description = "Allow inbound traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP traffic from ALB's security group
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
    description     = "Allow HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance_sg"
  }
}

# Attach the security group to the instances



variable "instances" {
  type = map(object({
    user_data = string
  }))
  default = {
    "instance-private-1" = {
      user_data = <<-EOF
#!/bin/bash
sudo su
# Update system packages
yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Make Docker Compose available globally
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create directories for the project and configurations
mkdir -p /home/ec2-user/stock-app /home/ec2-user/promtail/config /home/ec2-user/loki/data /home/ec2-user/loki/config

# Set MongoDB URI variable (using the MongoDB EC2 IP 3.237.173.0 and appropriate credentials)
MONGO_URI="mongodb://root:password@3.237.173.0:27017/"

# Create the Promtail configuration file
cat <<EOF1 > /home/ec2-user/promtail/config/config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  # New job to scrape logs locally from stock-app
  - job_name: stock-app-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: stock-app-logs
          __path__: /home/ec2-user/stock-app/logs/*.log
EOF1

# Create the Docker Compose file
cat <<EOF2 > /home/ec2-user/docker-compose.yml
version: '3'
services:
  promtail:
    image: gabecasis/promtail:2
    container_name: promtail
    ports:
      - "9080:9080"
    volumes:
      - ./promtail/config/config.yml:/etc/promtail/config.yml
      - /home/ec2-user/stock-app/logs:/home/ec2-user/stock-app/logs
    networks:
      - app-network

  stock-app:
    image: gabecasis/stock-app:5
    ports:
      - "5001:5001"
      - "8000:8000"
    environment:
      MONGO_URI: "$MONGO_URI"
    volumes:
      - /home/ec2-user/stock-app/logs:/app/logs
    command: ["--mongo_uri", "$MONGO_URI"]
    networks:
      - app-network

  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    networks:
      - app-network
    restart: always

networks:
  app-network:
    driver: bridge
EOF2

# Pull the latest Docker images
sudo docker-compose pull

# Run docker-compose with MONGO_URI passed as an environment variable
sudo MONGO_URI=$MONGO_URI docker-compose up -d

EOF
    },
    "instance-private-2" = {
      user_data = <<-EOF
#!/bin/bash
sudo su
# Update system packages
yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Make Docker Compose available globally
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create directories for the project and configurations
mkdir -p /home/ec2-user/stock-app /home/ec2-user/promtail/config /home/ec2-user/loki/data /home/ec2-user/loki/config

# Set MongoDB URI variable (using the MongoDB EC2 IP 3.237.173.0 and appropriate credentials)
MONGO_URI="mongodb://root:password@3.237.173.0:27017/"

# Create the Promtail configuration file
cat <<EOF1 > /home/ec2-user/promtail/config/config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  # New job to scrape logs locally from stock-app
  - job_name: stock-app-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: stock-app-logs
          __path__: /home/ec2-user/stock-app/logs/*.log
EOF1

# Create the Docker Compose file
cat <<EOF2 > /home/ec2-user/docker-compose.yml
version: '3'
services:
  promtail:
    image: gabecasis/promtail:2
    container_name: promtail
    ports:
      - "9080:9080"
    volumes:
      - ./promtail/config/config.yml:/etc/promtail/config.yml
      - /home/ec2-user/stock-app/logs:/home/ec2-user/stock-app/logs
    networks:
      - app-network

  stock-app:
    image: gabecasis/stock-app:5
    ports:
      - "5001:5001"
      - "8000:8000"
    environment:
      MONGO_URI: "$MONGO_URI"
    volumes:
      - /home/ec2-user/stock-app/logs:/app/logs
    command: ["--mongo_uri", "$MONGO_URI"]
    networks:
      - app-network

  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    networks:
      - app-network
    restart: always

networks:
  app-network:
    driver: bridge
EOF2

# Pull the latest Docker images
sudo docker-compose pull

# Run docker-compose with MONGO_URI passed as an environment variable
sudo MONGO_URI=$MONGO_URI docker-compose up -d

EOF
    },
    "instance-private-3" = {
      user_data = <<-EOF
#!/bin/bash
# Update system packages
yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Make Docker Compose available globally
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create necessary directories for volumes
mkdir -p /home/ec2-user/prometheus /home/ec2-user/prometheus/config /home/ec2-user/prometheus/data
mkdir -p /home/ec2-user/grafana /home/ec2-user/grafana/provisioning /home/ec2-user/grafana/provisioning/dashboards /home/ec2-user/grafana/provisioning/datasources

# Change ownership of directories to ec2-user
chown -R ec2-user:ec2-user /home/ec2-user/*
chown -R 65534:65534 /home/ec2-user/prometheus
sudo chown -R 472:472 /home/ec2-user/grafana
sudo chmod -R 755 /home/ec2-user/grafana

# Create the Prometheus configuration file
cat <<EOF1 > /home/ec2-user/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'flask_stock_app'
    metrics_path: /metrics
    static_configs:
      - targets: ['44.200.157.188:8000']
EOF1

# Set Grafana datasource configuration file to pull from Prometheus and Loki
cat <<EOF2 > /home/ec2-user/grafana/provisioning/datasources/datasources.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: http://prometheus:9090
    isDefault: true
    version: 1
    editable: true

  - name: Loki
    type: loki
    access: proxy
    orgId: 1
    url: http://44.200.157.188:3100
    isDefault: false
    version: 1
    editable: true
EOF2

# Provision Grafana dashboards
cat <<EOF3 > /home/ec2-user/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
EOF3

# Create the Grafana Loki dashboard file
cat <<EOF4 > /home/ec2-user/grafana/provisioning/dashboards/loki_dashboard.json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "datasource": {
        "default": false,
        "type": "loki",
        "uid": "P8E80F9AEF21F6940"
      },
      "gridPos": {
        "h": 9,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "dedupStrategy": "none",
        "enableLogDetails": true,
        "prettifyLogMessage": false,
        "showCommonLabels": false,
        "showLabels": false,
        "showTime": true,
        "sortOrder": "Descending",
        "wrapLogMessage": false
      },
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "P8E80F9AEF21F6940"
          },
          "editorMode": "code",
          "expr": "{job=\"stock-app-logs\"}\n",
          "queryType": "range",
          "refId": "A"
        }
      ],
      "title": "Stock App Log Stream",
      "type": "logs"
    }
  ],
  "schemaVersion": 39,
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Stock App Logs",
  "uid": "stock-app-logs",
  "version": 1,
  "weekStart": ""
}
EOF4

# Create the Grafana stock-app dashboard file
cat <<EOF5 > /home/ec2-user/grafana/provisioning/dashboards/stock-app_dashboard.json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "gnetId": 15956,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "datasource": {
        "default": true,
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "0": {
                  "text": "DOWN"
                },
                "1": {
                  "text": "UP"
                }
              },
              "type": "value"
            },
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#d44a3a",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 0
              },
              {
                "color": "#299c46",
                "value": 1
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 16,
        "w": 4,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "background",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.2.0",
      "repeatDirection": "v",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "code",
          "exemplar": true,
          "expr": "current_stock_value",
          "format": "time_series",
          "interval": "$interval",
          "intervalFactor": 1,
          "legendFormat": "{{stock}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Ticker",
      "type": "stat"
    },
    {
      "datasource": {
        "default": true,
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "currencyUSD"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 16,
        "w": 20,
        "x": 4,
        "y": 0
      },
      "id": 138,
      "options": {
        "legend": {
          "calcs": [
            "mean"
          ],
          "displayMode": "table",
          "placement": "right",
          "showLegend": true
        },
        "tooltip": {
          "mode": "multi",
          "sort": "asc"
        }
      },
      "pluginVersion": "7.5.3",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "code",
          "exemplar": true,
          "expr": "current_stock_value",
          "format": "time_series",
          "interval": "$interval",
          "intervalFactor": 1,
          "legendFormat": "{{stock}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "All stock values",
      "type": "timeseries"
    },
    {
      "collapsed": false,
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 16
      },
      "id": 15,
      "panels": [],
      "repeat": "target",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "refId": "A"
        }
      ],
      "title": "$target ",
      "type": "row"
    }
  ],
  "refresh": "",
  "schemaVersion": 39,
  "tags": [
    "blackbox",
    "prometheus"
  ],
  "templating": {
    "list": [
      {
        "auto": true,
        "auto_count": 10,
        "auto_min": "10s",
        "current": {
          "selected": false,
          "text": "10s",
          "value": "10s"
        },
        "hide": 0,
        "label": "Interval",
        "name": "interval",
        "options": [
          {
            "selected": false,
            "text": "auto",
            "value": "$__auto_interval_interval"
          },
          {
            "selected": false,
            "text": "5s",
            "value": "5s"
          },
          {
            "selected": true,
            "text": "10s",
            "value": "10s"
          },
          {
            "selected": false,
            "text": "30s",
            "value": "30s"
          },
          {
            "selected": false,
            "text": "1m",
            "value": "1m"
          },
          {
            "selected": false,
            "text": "10m",
            "value": "10m"
          },
          {
            "selected": false,
            "text": "30m",
            "value": "30m"
          },
          {
            "selected": false,
            "text": "1h",
            "value": "1h"
          },
          {
            "selected": false,
            "text": "6h",
            "value": "6h"
          },
          {
            "selected": false,
            "text": "12h",
            "value": "12h"
          },
          {
            "selected": false,
            "text": "1d",
            "value": "1d"
          },
          {
            "selected": false,
            "text": "7d",
            "value": "7d"
          },
          {
            "selected": false,
            "text": "14d",
            "value": "14d"
          },
          {
            "selected": false,
            "text": "30d",
            "value": "30d"
          }
        ],
        "query": "5s,10s,30s,1m,10m,30m,1h,6h,12h,1d,7d,14d,30d",
        "refresh": 2,
        "skipUrlSync": false,
        "type": "interval"
      },
      {
        "current": {
          "selected": false,
          "text": "All",
          "value": "$__all"
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "definition": "label_values(stock_price, stock_symbol)",
        "hide": 0,
        "includeAll": true,
        "multi": true,
        "name": "target",
        "options": [],
        "query": {
          "query": "label_values(stock_price, stock_symbol)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-30m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "Stock dashboard",
  "uid": "ferebtebh3",
  "version": 1,
  "weekStart": ""
}
EOF5

# Create Docker Compose file
cat <<EOF6 > /home/ec2-user/docker-compose.yml
version: '3'
services:
  prometheus:
    image: gabecasis/prometheus:2
    ports:
      - "9090:9090"
    networks:
      - app-network
    restart: always
    volumes:
      - ./prometheus:/prometheus
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: gabecasis/grafana:2
    ports:
      - "3000:3000"
    networks:
      - app-network
    restart: always
    volumes:
      - ./grafana:/var/lib/grafana
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

networks:
  app-network:
    driver: bridge
EOF6



# Navigate to the directory and bring up the services
cd /home/ec2-user
docker-compose up -d
EOF
    },
    "instance-private-4" = {
      user_data = <<-EOF
#!/bin/bash
# Update the system packages
yum update -y

# Install Docker
yum install -y docker

# Start and enable Docker service
sudo service docker start
sudo chkconfig docker on

# Pull MongoDB and Mongo Express images
sudo docker pull mongo:latest
sudo docker pull mongo-express:latest

# Create a Docker network for MongoDB and Mongo Express
sudo docker network create mongo-network

# Remove any existing MongoDB container (if exists)
sudo docker rm -f mongodb

# Run MongoDB container on the created Docker network with persistent storage
sudo docker run -d --name mongo --network mongo-network -p 27017:27017 \
  -v mongo_data:/data/db \
  mongo:latest

# Remove any existing Mongo Express container (if exists)
sudo docker rm -f mongo-express

# Run Mongo Express container on the created Docker network and link it to MongoDB
sudo docker run -d --name mongo-express --network mongo-network -p 8081:8081 \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=pass \
  mongo-express:latest
EOF
    }
  }
}
