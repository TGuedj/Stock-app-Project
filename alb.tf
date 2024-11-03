############################################
##########     ALB Security Group   ########
############################################
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP traffic to ALB and apps"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules for the applications
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic to ALB (port 80)
  }

  # Flask (Port 5001)
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to Flask app (port 5001)
  }

  # Mongo Express (Port 8081)
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to Mongo Express (port 8081)
  }

  # Promtail (Port 9080)
  ingress {
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to Promtail (port 9080)
  }

  # Grafana (Port 3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to Grafana (port 3000)
  }
  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic to Grafana (port 3000)
  }

  # Egress (outbound traffic, allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "alb_sg"
  }
}

############################################
##########       ALB Setup        ##########
############################################
# ALB Setup
resource "aws_lb" "app__lb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "my-alb"
  }
}




########################################################
##########   Target Groups and Health Checks  ##########   
########################################################

# Flask App Target Group (Port 5001)
resource "aws_lb_target_group" "flask_tg" {
  name        = "flask-tg"
  port        = 5001
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"              # Define the health check path
    protocol            = "HTTP"
    port                = "5001"           # Health check on the same port as the application
    interval            = 30               # Interval between health checks (30 seconds)
    timeout             = 5                # Timeout for health check response (5 seconds)
    healthy_threshold   = 2                # Number of successes to mark as healthy
    unhealthy_threshold = 2                # Number of failures to mark as unhealthy
    matcher             = "200"            # HTTP 200 OK expected for a healthy response
  }

  tags = {
    Name = "flask-tg"
  }
}

# Mongo Express Target Group (Port 8081)
resource "aws_lb_target_group" "mongoexpress_tg" {
  name        = "mongoexpress-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/status"              # Define the health check path
    protocol            = "HTTP"
    port                = "8081"           # Health check on the same port as Mongo Express
    interval            = 30               # Interval between health checks (30 seconds)
    timeout             = 5                # Timeout for health check response (5 seconds)
    healthy_threshold   = 2                # Number of successes to mark as healthy
    unhealthy_threshold = 2                # Number of failures to mark as unhealthy
    matcher             = "200"            # HTTP 200 OK expected for a healthy response
  }

  tags = {
    Name = "mongoexpress-tg"
  }
}

# Promtail Target Group (Port 9080)
resource "aws_lb_target_group" "promtail_tg" {
  name        = "promtail-tg"
  port        = 9080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/metrics"       # Health check endpoint for Promtail
    protocol            = "HTTP"
    port                = "9080"           # Health check on the same port as Promtail
    interval            = 30               # Interval between health checks (30 seconds)
    timeout             = 5                # Timeout for health check response (5 seconds)
    healthy_threshold   = 2                # Number of successes to mark as healthy
    unhealthy_threshold = 2                # Number of failures to mark as unhealthy
    matcher             = "200"            # HTTP 200 OK expected for a healthy response
  }

  tags = {
    Name = "promtail-tg"
  }
}

# Grafana Target Group (Port 3000)
resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/login"              # Health check endpoint for Grafana
    protocol            = "HTTP"
    port                = "3000"           # Health check on the same port as Grafana
    interval            = 30               # Interval between health checks (30 seconds)
    timeout             = 5                # Timeout for health check response (5 seconds)
    healthy_threshold   = 2                # Number of successes to mark as healthy
    unhealthy_threshold = 2                # Number of failures to mark as unhealthy
    matcher             = "200"            # HTTP 200 OK expected for a healthy response
  }

  tags = {
    Name = "grafana-tg"
  }
}

# Loki Target Group (Port 3100)
resource "aws_lb_target_group" "loki_tg" {
  name        = "loki-tg"
  port        = 3100
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/loki/api/v1/status/ready"  # Change this based on Loki's readiness endpoint
    protocol            = "HTTP"
    port                = "3100"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "loki-tg"
  }
}

############################################
##########     ALB Listeners      ########## 
############################################

# ALB Listener for HTTP traffic on port 80
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app__lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn  # Default route to Flask app
  }
}

############################################
##########    ALB Listener Rules   #########
############################################

# Listener for Flask App (Port 5001)
resource "aws_lb_listener" "flask_listener" {
  load_balancer_arn = aws_lb.app__lb.arn
  port              = 5001
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }
}

# Listener for Mongo Express (Port 8081)
resource "aws_lb_listener" "mongo_express_listener" {
  load_balancer_arn = aws_lb.app__lb.arn
  port              = 8081
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mongoexpress_tg.arn  # Correct reference to target group ARN
  }
}


# Listener for Promtail (Port 9080)
resource "aws_lb_listener" "promtail_listener" {
  load_balancer_arn = aws_lb.app__lb.arn
  port              = 9080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.promtail_tg.arn
  }
}

# Listener for Grafana (Port 3000)
resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.app__lb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}


# Listener for Loki (Port 3100)
resource "aws_lb_listener" "loki_listener" {
  load_balancer_arn = aws_lb.app__lb.arn
  port              = 3100
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki_tg.arn
  }
}


##############################################
##########  Target Group Attachments #########
##############################################

# Attach Flask instances to Flask target group
resource "aws_lb_target_group_attachment" "flask_attachment_1" {
  target_group_arn = aws_lb_target_group.flask_tg.arn
  target_id        = module.web_instance["instance-private-1"].id
  port             = 5001  # Flask runs on port 5001
}

resource "aws_lb_target_group_attachment" "flask_attachment_2" {
  target_group_arn = aws_lb_target_group.flask_tg.arn
  target_id        = module.web_instance["instance-private-2"].id
  port             = 5001  # Flask runs on port 5001
}

# Attach Grafana instance to Grafana target group
resource "aws_lb_target_group_attachment" "grafana_attachment" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = module.web_instance["instance-private-3"].id
  port             = 3000  # Grafana runs on port 3000
}



# Attach Mongo Express instance to Mongo Express target group
resource "aws_lb_target_group_attachment" "mongoexpress_attachment" {
  target_group_arn = aws_lb_target_group.mongoexpress_tg.arn
  target_id        = module.web_instance["instance-private-4"].id  # The instance where Mongo Express is running
  port             = 8081  # Mongo Express runs on port 8081
}


# Attach Promtail instance to Promtail target group
resource "aws_lb_target_group_attachment" "promtail_attachment" {
  target_group_arn = aws_lb_target_group.promtail_tg.arn
  target_id        = module.web_instance["instance-private-2"].id  # Adjust this to the instance where Promtail is running
  port             = 9080  # Promtail runs on port 9080
}



# Attach Loki instance to Loki target group
resource "aws_lb_target_group_attachment" "loki_attachment" {
  target_group_arn = aws_lb_target_group.loki_tg.arn
  target_id        = module.web_instance["instance-private-2"].id  # Adjust this to the instance where Loki is running
  port             = 3100  # Loki runs on port 3100
}